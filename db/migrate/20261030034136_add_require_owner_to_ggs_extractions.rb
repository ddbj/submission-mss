class AddRequireOwnerToGgsExtractions < ActiveRecord::Migration[8.1]
  def change
    add_column :ggs_extractions, :require_owner, :boolean, null: false, default: false
  end
end
