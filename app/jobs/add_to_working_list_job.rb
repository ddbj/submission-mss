class AddToWorkingListJob < ApplicationJob
  queue_as :default

  def perform(submission)
    WorkingList.instance.add_new_submission submission
  end
end
