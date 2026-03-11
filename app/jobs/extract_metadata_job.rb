class ExtractMetadataJob < ApplicationJob
  def perform(extraction)
    ActiveRecord::Base.transaction do
      begin
        extraction.prepare_files
      rescue DfastExtraction::ExtractionError => e
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
  end
end
