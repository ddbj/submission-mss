class AddApiKeyToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :uid,   :string
    add_column :users, :email, :string

    execute <<~SQL
      UPDATE users SET uid = id_token->>'preferred_username', email = id_token->>'email';
    SQL

    change_column_null :users, :uid,   false
    change_column_null :users, :email, false

    add_index :users, :uid, unique: true

    add_column :users, :api_key, :string

    User.find_each do |user|
      user.update! api_key: User.generate_api_key
    end

    change_column_null :users, :api_key, false

    add_index :users, :api_key, unique: true

    remove_column :users, :openid_sub
    remove_column :users, :id_token
  end
end
