class RemoveApiKeyFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :api_key, :string, null: false
  end
end
