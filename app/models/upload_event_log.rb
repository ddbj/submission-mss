class UploadEventLog
  def self.append(upload)
    submission = upload.submission

    line = {
      mass_id:           submission.mass_id,
      dway_account:      submission.user.uid,
      data_arrival_date: upload.timestamp
    }.to_json

    path = Rails.application.config_for(:app).upload_events_log!

    File.open path, 'a' do |f|
      f.flock File::LOCK_EX
      f.write "#{line}\n"
    end
  end
end
