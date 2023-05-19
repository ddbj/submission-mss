class AddErrorToExtractions < ActiveRecord::Migration[7.0]
  def change
    add_column :dfast_extractions,          :error, :jsonb
    add_column :mass_directory_extractions, :error, :jsonb
  end
end
