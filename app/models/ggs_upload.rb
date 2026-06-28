class GgsUpload < ApplicationRecord
  include ExtractionUpload

  belongs_to :extraction, class_name: 'GgsExtraction'

  def job_ids = extraction.ggs_job_ids
end
