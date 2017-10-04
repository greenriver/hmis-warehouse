class CreateExports < ActiveRecord::Migration
  def change
    create_table :exports do |t|
      # a hash of project ids, start date, end_date, period type,
      # diretive and hash status, user_id
      t.string :export_id, index: true 
      t.references :user
      t.date :start_date
      t.date :end_date
      t.integer :period_type
      t.integer :directive
      t.integer :hash_status
      t.timestamps null: false
      t.datetime :deleted_at, index: true
    end
  end
end