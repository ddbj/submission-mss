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
end
