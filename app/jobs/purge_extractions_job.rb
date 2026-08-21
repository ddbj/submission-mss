class PurgeExtractionsJob < ApplicationJob
  # An extraction is scratch space: the files are gathered so the submitter can
  # look them over, and copied into the submission when they send them. Long
  # enough that nothing in that exchange is cut short, short enough that what
  # was thought better of does not sit under the extracts directory for good.
  RETENTION = 7.days

  def perform
    extraction_classes.each do |klass|
      # Every one of them, not only those that still have file records. A
      # directory is made outside the transaction the records are made in, so a
      # failure that is not an Extraction::Error rolls the records back and
      # leaves the directory -- which is the case most worth sweeping, and the
      # one a records-first query cannot see. discard_files does nothing when
      # there is nothing to do.
      klass.where(created_at: ..RETENTION.ago).find_each(&:discard_files)
    end
  end

  private

  # Taken from the ways of uploading rather than listed again here, so that a
  # kind of extraction added later is swept without anyone remembering to.
  def extraction_classes
    Upload::VIA.values.map(&:constantize).filter_map {
      _1.extraction_class if _1.respond_to?(:extraction_class)
    }
  end
end
