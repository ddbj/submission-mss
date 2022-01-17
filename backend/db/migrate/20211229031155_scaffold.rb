class Scaffold < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :openid_sub, null: false, index: {unique: true}
      t.jsonb  :id_token,   null: false

      t.timestamps
    end

    create_table :submissions do |t|
      t.references :user, null: false

      t.boolean :tpa,            null: false
      t.boolean :dfast,          null: false
      t.integer :entries_count,  null: false
      t.date    :hold_date
      t.jsonb   :contact_person, null: false
      t.jsonb   :other_people,   null: false, array: true
      t.string  :sequencer,      null: false
      t.string  :data_type,      null: false
      t.string  :description,    null: false
      t.string  :email_language, null: false

      t.timestamps
    end
  end
end
