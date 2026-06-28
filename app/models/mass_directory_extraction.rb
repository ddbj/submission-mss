class MassDirectoryExtraction < ApplicationRecord
  include Extraction
  include ArchiveExtraction

  def prepare_files
    ActiveRecord::Base.transaction do
      unarchive_and_copy_files(user_mass_dir, working_dir) do |name|
        files.create!(name:, parsing: true)
      end
    end
  end

  private

  def user_mass_dir
    Rails.application.config_for(:app).mass_dir_path_template!.gsub('{user}', user.uid).tap {|path|
      raise "malformed directory path: #{path}" unless path == File.expand_path(path)
    }.then { Pathname.new(_1) }
  end
end
