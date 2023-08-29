class DropDfastOnSubmissions < ActiveRecord::Migration[7.0]
  def change
    remove_column :submissions, :dfast, :boolean, null: false
  end
end
