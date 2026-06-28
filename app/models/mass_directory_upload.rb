class MassDirectoryUpload < ApplicationRecord
  include ExtractionUpload

  belongs_to :extraction, class_name: 'MassDirectoryExtraction'

  def job_ids = nil
end
