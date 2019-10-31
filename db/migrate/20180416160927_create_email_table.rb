class CreateEmailTable < ActiveRecord::Migration[4.2]
  def change
    create_table :messages do |t|
      t.references :user
      t.string :from, null: false
      t.string :subject, null: false
      t.text :body, null: false
      t.boolean :html, null: false, default: false
      t.datetime :seen_at
      t.datetime :sent_at

      t.timestamps null: false
    end
  end
end
