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
      t.string  :sequencer,      null: false
      t.string  :data_type,      null: false
      t.string  :description
      t.string  :email_language, null: false

      t.virtual :mass_id, type: :string, as: %('NSUB' || LPAD(CAST(id AS text), 6, '0')), stored: true, index: true

      t.timestamps
    end

    create_table :uploads do |t|
      t.references :submission, null: false

      t.boolean :copied, null: false, default: false

      t.timestamps
    end

    create_table :contact_people do |t|
      t.references :submission, null: false

      t.string :email,       null: false
      t.string :full_name,   null: false
      t.string :affiliation, null: false

      t.timestamps
    end

    create_table :other_people do |t|
      t.references :submission, null: false

      t.string  :email,     null: false
      t.string  :full_name, null: false
      t.integer :position,  null: false, index: true

      t.timestamps
    end
  end
end
