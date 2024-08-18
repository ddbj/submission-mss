require "open-uri"

class DfastExtraction < ApplicationRecord
  class ExtractionError < StandardError
    def initialize(id, **data)
      @id   = id
      @data = data
    end

    attr_reader :id, :data
  end

  belongs_to :user

  has_many :files, dependent: :destroy, class_name: "DfastExtractionFile", foreign_key: :extraction_id

  validates :dfast_job_ids, presence: true

  def prepare_files
    working_dir.mkpath

    ActiveRecord::Base.transaction do
      dfast_job_ids.each do |job_id|
        fetch_and_copy_files job_id
      end
    end
  end

  def working_dir
    Pathname.new(ENV.fetch("EXTRACTION_WORKDIR")).join("mssform-dfast-uri-extraction-#{id}")
  end

  private

  def fetch_and_copy_files(job_id)
    URI.parse("https://dfast.ddbj.nig.ac.jp/analysis/download/#{job_id}/ddbj_submission.zip").open do |body|
      zip = Zip::InputStream.new(body)

      while entry = zip.get_next_entry
        next unless entry.name.end_with?(".ann", ".fasta")

        dest_name = normalize_path(entry.name)

        working_dir.join(dest_name).open "w" do |dest|
          IO.copy_stream entry.get_input_stream, dest

          files.create!(
            name:         dest_name,
            parsing:      true,
            dfast_job_id: job_id
          )
        end
      end
    end
  rescue OpenURI::HTTPError => e
    raise ExtractionError.new(:failed_to_fetch, job_id:, reason: e.io.status.join(" "))
  end

  def normalize_path(path)
    path.to_s.gsub(%r{[/ ]}, "/" => "__", " " => "_")
  end
end
