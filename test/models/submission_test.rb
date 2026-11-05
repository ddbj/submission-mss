require 'test_helper'

class SubmissionTest < ActiveSupport::TestCase
  test 'a hold date that does not exist' do
    submission = Submission.new(hold_date: '2025-02-29')

    submission.validate

    assert_includes submission.errors.details[:hold_date], {error: :invalid}
  end

  test 'no hold date' do
    submission = Submission.new(hold_date: nil)

    submission.validate

    assert_empty submission.errors.details[:hold_date]
  end

  test 'portal_url: the mass ID filled in' do
    submission = submissions(:alice_submission).tap { it.portal_managed = true }

    with_app_config portal_submission_url_template: 'https://portal.example.org/submissions/{mass_id}?id={mass_id}' do
      assert_equal 'https://portal.example.org/submissions/NSUB000001?id=NSUB000001', submission.portal_url
    end
  end

  test 'portal_url: not one the portal made' do
    submission = submissions(:alice_submission)

    with_app_config portal_submission_url_template: 'https://portal.example.org/submissions/{mass_id}' do
      assert_nil submission.portal_url
    end
  end

  test 'portal_url: nowhere to send them' do
    submission = submissions(:alice_submission).tap { it.portal_managed = true }

    with_app_config portal_submission_url_template: '' do
      assert_nil submission.portal_url
    end

    with_app_config portal_submission_url_template: nil do
      assert_nil submission.portal_url
    end
  end

  test 'portal_url: only https' do
    submission = submissions(:alice_submission).tap { it.portal_managed = true }

    with_app_config portal_submission_url_template: 'http://portal.example.org/submissions/{mass_id}' do
      assert_nil submission.portal_url
    end
  end
end
