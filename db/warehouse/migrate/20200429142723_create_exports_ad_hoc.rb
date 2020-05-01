class CreateExportsAdHoc < ActiveRecord::Migration[5.2]
  def change
    create_table :exports_ad_hocs do |t|
      t.references :user, index: true, null: false
      t.jsonb :options
      t.jsonb :headers
      t.jsonb :rows
      t.integer :client_count
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps null: false, index: true
      t.datetime :deleted_at
    end
  end
end
