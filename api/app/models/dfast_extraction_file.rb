class DfastExtractionFile < ApplicationRecord
  include ExtractionFile

  belongs_to :extraction, class_name: "DfastExtraction"
end
