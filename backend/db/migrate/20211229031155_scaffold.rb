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

    create_table :contact_people do |t|
      t.references :submission, null: false, foreign_key: true

      t.string :email,       null: false
      t.string :full_name,   null: false
      t.string :affiliation, null: false

      t.timestamps
    end
  end
end
