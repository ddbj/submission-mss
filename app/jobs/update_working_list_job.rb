class UpdateWorkingListJob < ApplicationJob
  queue_as :default

  def perform(submission)
    WorkingList.instance.update_data_arrival_date submission
  end
end
