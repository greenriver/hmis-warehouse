class CreateEmailTable < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.references :user
      t.string :subject, null: false
      t.text :body, null: false
      t.string :from, null: false
      t.datetime :seen_at
      t.datetime :sent_at

      t.timestamps null: false
    end
  end
end
