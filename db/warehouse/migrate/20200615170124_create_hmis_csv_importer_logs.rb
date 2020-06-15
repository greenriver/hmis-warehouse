class CreateHmisCsvImporterLogs < ActiveRecord::Migration[5.2]
  def up

    create_table :hmis_csv_importer_logs do |t|
      t.integer :data_source_id, null: false, index: true
      t.jsonb :summary
      t.string :status
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps index: true
      t.integer :upload_id
    end

    create_table :hmis_csv_import_errors do |t|
      t.integer :importer_log_id, null: false, index: true
      t.string :message
      t.string :details
      t.string :source_type, null: false
      t.string :source_id, null: false
    end
    add_index :hmis_csv_import_errors, [:source_type, :source_id], name: 'hmis_csv_import_errors-' + SecureRandom.alphanumeric(4)

    remove_column :hmis_csv_loader_logs, :load_errors, :jsonb
    add_column :hmis_csv_loader_logs, :importer_log_id, :integer, index: true

    drop_table :hmis_csv_validations, if_exists: true
    create_table :hmis_csv_import_validations do |t|
      t.integer :importer_log_id, null: false, index: true
      t.string :type, null: false, index: true
      t.string :source_id, null: false
      t.string :source_type, null: false
      t.string :status
    end
    add_index :hmis_csv_import_validations, [:source_type, :source_id], name: 'hmis_csv_validations-' + SecureRandom.alphanumeric(4)
  end

  def down
    drop_table :hmis_csv_importer_logs
    drop_table :hmis_csv_import_errors
    drop_table :hmis_csv_import_validations
    remove_column :hmis_csv_loader_logs, :importer_log_id, :integer, index: true
    add_column :hmis_csv_loader_logs, :load_errors, :jsonb

  end
end
