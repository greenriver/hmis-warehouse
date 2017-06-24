class AddTokenToProjectDataQualityReport < ActiveRecord::Migration
  def change
    create_table :report_tokens do |t|
      t.references :report, index: true, null: false
      t.references :contact, index: true, null: false
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.datetime :accessed_at
      t.timestamps
    end
  end
end
