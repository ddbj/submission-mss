class DfastUpload < ApplicationRecord
  include ExtractionUpload

  belongs_to :extraction, class_name: 'DfastExtraction'

  def job_ids = extraction.dfast_job_ids
end
