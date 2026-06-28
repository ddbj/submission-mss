class GgsExtractionFile < ApplicationRecord
  include ExtractionFile

  belongs_to :extraction, class_name: 'GgsExtraction'

  def fullpath = extraction.working_dir.join(ggs_job_id, name)
end
