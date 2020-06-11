class CreateCsvLoaderLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :hmis_csv_loader_logs do |t|
      t.integer :data_source_id, null: false, index: true
      t.jsonb :summary
      t.string :status
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps index: true
      t.integer :upload_id
    end

    create_table :hmis_csv_files do |t|
      t.integer :data_source_id, null: false, index: true
      t.integer :hmis_csv_loader_log_id, null: false, index: true
      t.string :filename
      t.string :file_type
      t.timestamps index: true
    end

     create_table :hmis_csv_errors do |t|
      t.integer :data_source_id, null: false, index: true
      t.integer :hmis_csv_loader_log_id, null: false, index: true
      t.string :type, null: false, index: true
      t.string :source_id, null: false
      t.string :source_type, null: false
    end

    add_index :hmis_csv_errors, [:source_type, :source_id]
  end
end
