class PurgeUnattachedUploadsJob < ApplicationJob
  queue_as :default

  def perform
    ActiveStorage::Blob.unattached.where(created_at: ..2.days.ago).find_each(&:purge_later)
  end
end
