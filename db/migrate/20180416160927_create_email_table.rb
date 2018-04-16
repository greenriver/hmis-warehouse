class CreateEmailTable < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :subject, null: false
      t.text :body, null: false
      t.string :to, null: false, array: true, index: { using: :gin }
      t.string :from, null: false, array: true
      t.datetime :seen_at
      t.datetime :sent_at

      t.timestamps null: false
    end
  end
end
