class PurgeUnattachedUploadsJob < ApplicationJob
  # A blob whose service is gone cannot be purged: what it points at went with
  # the service, and asking a blob for its service raises. Reported once, rather
  # than once per blob by the purge that would fail on each of them.
  class StrandedBlobs < StandardError; end

  # How long a blob a direct upload made is left alone. Long enough for the
  # application it belongs to to be finished and sent, which WebuiUpload counts
  # on: a signed ID older than this names a blob that is no longer there.
  RETENTION = 2.days

  queue_as :default

  def perform
    stranded = Hash.new(0)

    ActiveStorage::Blob.unattached.where(created_at: ..RETENTION.ago).find_each do |blob|
      if service_configured?(blob)
        blob.purge_later
      else
        stranded[blob.service_name] += 1
      end
    end

    report stranded if stranded.any?
  end

  private

  # Whether we could reach the blob at all, not whether it is there. The block
  # is what makes this a question: without it, fetch raises for a service
  # nothing is configured for.
  def service_configured?(blob)
    ActiveStorage::Blob.services.fetch(blob.service_name) { nil }.present?
  end

  def report(stranded)
    counts = stranded.sort.map {|service, count| "#{count} in #{service}" }

    Rails.error.report(
      StrandedBlobs.new("nothing is configured for the service these blobs name: #{counts.to_sentence}"),
      handled: true
    )
  end
end
