class MassDirectoryExtractionFile < ApplicationRecord
  include ExtractionFile

  belongs_to :extraction, class_name: 'MassDirectoryExtraction'
end
