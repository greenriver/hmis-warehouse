class CreatePremiumPayments < ActiveRecord::Migration
  def change
    create_table :premium_payments do |t|
      t.references :user
      t.text :content
      t.string :original_filename
      t.timestamps null: false
      t.datetime :deleted_at, index: true
    end
  end
end
