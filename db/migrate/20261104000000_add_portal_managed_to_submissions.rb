class AddPortalManagedToSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_column :submissions, :portal_managed, :boolean, null: false, default: false
  end
end
