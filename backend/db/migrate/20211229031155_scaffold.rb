class Scaffold < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :openid_sub,                null: false, index: {unique: true}
      t.string :openid_preferred_username, null: false

      t.timestamps
    end

    create_table :submissions do |t|
      t.references :user, null: false

      t.boolean :tpa,            null: false
      t.boolean :dfast,          null: false
      t.integer :entries_count,  null: false
      t.date    :hold_date
      t.string  :sequencer,      null: false
      t.string  :data_type,      null: false
      t.string  :short_title
      t.string  :description,    null: false
      t.string  :email_language, null: false

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
