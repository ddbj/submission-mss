class AddMassIdToSubmissions < ActiveRecord::Migration[7.0]
  def change
    remove_column :submissions, :mass_id, :string, as: %('NSUB' || LPAD(CAST(id AS text), 6, '0')), stored: true, index: true
    add_column :submissions, :mass_id, :string

    execute <<~SQL
      UPDATE submissions SET mass_id = 'NSUB' || LPAD(CAST(id AS text), 6, '0')
    SQL

    change_column_null :submissions, :mass_id, false
    add_index :submissions, :mass_id, unique: true
  end
end
