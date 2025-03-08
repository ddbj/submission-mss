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
    dir = Rails.application.config_for(:app).extracts_dir!

    Pathname.new(dir).join("dfast-#{id}")
  end

  private

  def fetch_and_copy_files(job_id)
    res = Fetch::API.fetch("https://dfast.ddbj.nig.ac.jp/analysis/download/#{job_id}/ddbj_submission.zip")

    raise ExtractionError.new(:failed_to_fetch, job_id:, reason: "#{res.status} #{res.status_text}") unless res.ok

    zip = Zip::InputStream.new(StringIO.new(res.body))

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

  def normalize_path(path)
    path.to_s.gsub(%r{[/ ]}, "/" => "__", " " => "_")
  end
end
