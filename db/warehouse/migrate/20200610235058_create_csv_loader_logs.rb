class CreateCsvLoaderLogs < ActiveRecord::Migration[5.2]
  def up
    create_table :hmis_csv_loader_logs do |t|
      t.integer :data_source_id, null: false, index: true
      t.jsonb :summary
      t.jsonb :load_errors
      t.string :status
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps index: true
      t.integer :upload_id
    end

    create_table :hmis_csv_validations do |t|
      t.integer :data_source_id, null: false, index: true
      t.integer :hmis_csv_loader_log_id, null: false, index: true
      t.string :type, null: false, index: true
      t.string :source_id, null: false
      t.string :source_type, null: false
      t.string :status
    end

    add_index :hmis_csv_validations, [:source_type, :source_id], name: 'hmis_csv_validations-' + SecureRandom.alphanumeric(4)
  end

  def down
    drop_table :hmis_csv_loader_logs
    drop_table :hmis_csv_validations
  end
end
