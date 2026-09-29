class ExtractMetadataJob < ApplicationJob
  def perform(extraction)
    # Run again by hand after it failed, it would be too late: the extraction
    # was turned down and the submitter has stopped waiting for it.
    return unless extraction.state == 'pending'

    ActiveRecord::Base.transaction do
      begin
        extraction.prepare_files
      rescue Extraction::Error => e
        # A partly-processed directory may have created some file records and
        # copied some files before failing; discard both so a rejected
        # extraction keeps nothing.
        extraction.discard_files
        extraction.update! state: 'rejected', error: {id: e.id, **e.data}
        return
      end

      extraction.files.find_each do |file|
        warnings, parsed_data = file.parse

        file.update!(
          parsing:     false,
          parsed_data:,
          _errors:     warnings
        )
      rescue ExtractionFile::ParseError => e
        file.update!(
          parsing:     false,
          parsed_data: nil,

          _errors: [
            {severity: e.severity, id: e.id, value: e.value}
          ]
        )
      end

      extraction.update! state: 'fulfilled'
    end
  rescue StandardError
    # Anything else is our own failure, not something wrong with what the
    # submitter handed us. Say so rather than leave them waiting on an
    # extraction that will never finish, and let it be reported all the same.
    # What was gathered goes, as for a rejection above: the transaction takes
    # the records back only when it is the outermost one, and never the files.
    extraction.discard_files
    extraction.update! state: 'rejected', error: {id: 'unexpected', reason: 'An unexpected error occurred. Please try again later.'}

    raise
  end
end
