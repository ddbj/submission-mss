require 'test_helper'

class WorkingListTest < ActiveSupport::TestCase
  test 'a submission whose uploads have all been taken away still makes a row' do
    submission = submissions(:alice_submission)

    submission.uploads.destroy_all

    # The row is a dozen queries about a submission, and one of them used to be
    # asked of an upload that was assumed to be there. Nothing sends a
    # submission with no uploads, but nothing stops one being left that way
    # either, and a sheet write is not where that should first be noticed.
    row = WorkingList.instance.to_row(submission.reload)

    assert_equal submission.mass_id, row.fetch(:mass_id)
    assert_nil   row.fetch(:upload_via)
    assert_equal '', row.fetch(:data_arrival_date)
  end
end
