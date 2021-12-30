class Scaffold < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :openid_sub, null: false, index: {unique: true}

      t.timestamps
    end

    create_table :submissions do |t|
      t.references :user

      t.timestamps
    end
  end
end
