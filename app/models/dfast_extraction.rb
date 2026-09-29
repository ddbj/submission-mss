class DfastExtraction < ApplicationRecord
  include Extraction

  validates :dfast_job_ids, presence: true

  def prepare_files
    working_dir.mkpath

    ActiveRecord::Base.transaction do
      # The same job pasted twice would clash with itself.
      dfast_job_ids.uniq.each do |job_id|
        fetch_and_copy_files job_id
      end
    end
  end

  private

  def fetch_and_copy_files(job_id)
    raise Extraction::Error.new(:invalid_job_id, job_id:) unless job_id.match?(UUID_FORMAT)

    res = Fetch::API.fetch("https://dfast.ddbj.nig.ac.jp/analysis/download/#{job_id}/ddbj_submission.zip")

    raise Extraction::Error.new(:failed_to_fetch, job_id:, detail: "#{res.status} #{res.status_text}".strip) unless res.ok

    zip = Zip::InputStream.new(StringIO.new(res.body))

    while entry = zip.get_next_entry
      next unless entry.name.end_with?('.ann', '.fasta')

      dest_name = normalize_path(entry.name)

      # Different DFAST jobs can contain a file with the same name; reject the
      # collision with the offending name instead of hitting the unique index.
      if other = files.find_by(name: dest_name)
        raise Extraction::Error.new(:duplicate_file_name, file: dest_name) if other.dfast_job_id == job_id
        raise Extraction::Error.new(:duplicate_file_name_across_jobs, file: dest_name, job_id:, other_job_id: other.dfast_job_id)
      end

      working_dir.join(dest_name).open 'w' do |dest|
        IO.copy_stream entry.get_input_stream, dest

        files.create!(
          name:         dest_name,
          parsing:      true,
          dfast_job_id: job_id
        )
      end
    end
  end
end
