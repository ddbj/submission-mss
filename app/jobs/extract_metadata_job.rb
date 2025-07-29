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
        file.update!(
          parsing:     false,
          parsed_data: file.parse,
          _errors:     []
        )
      rescue ExtractionFile::ParseError => e
        file.update!(
          parsing:     false,
          parsed_data: nil,

          _errors: [
            {id: e.id, value: e.value}
          ]
        )
      end

      extraction.update! state: 'fulfilled'
    end
  end
end
