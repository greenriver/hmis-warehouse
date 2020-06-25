class CreateTwentyTwentyDataLake < ActiveRecord::Migration[5.2]
  def up
    HmisCsvTwentyTwenty::Importer::Importer.importable_files.each do |_, klass|
      klass.hmis_table_create!(version: '2020', constraints: false)
      klass.hmis_table_create_indices!(version: '2020')
    end
    HmisCsvTwentyTwenty::Loader::Loader.importable_files.each do |_, klass|
      klass.hmis_table_create!(version: '2020', constraints: false, types: false)
      klass.hmis_table_create_indices!(version: '2020')
    end

    HmisCsvTwentyTwenty::Importer::Importer.importable_files.each_value do |klass|
      column_names = klass.column_names
      add_column klass.table_name, :data_source_id, :integer, null: false, index: true
      add_column klass.table_name, :importer_log_id, :integer, index: true, null: false
      add_column klass.table_name, :pre_processed_at, :datetime, null: false
      add_column klass.table_name, :source_hash, :string
      add_column klass.table_name, :source_id, :integer, null: false
      add_column klass.table_name, :source_type, :string, null: false

      add_column klass.table_name, :dirty_at, :timestamp, index: true
      add_column klass.table_name, :clean_at, :timestamp, index: true

      add_index klass.table_name, [:source_type, :source_id], name: klass.table_name + '-' + SecureRandom.alphanumeric(4)
      add_index klass.table_name, [klass.hud_key, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"
      puts klass.hud_key
      if column_names.include?('EnrollmentID') && ! klass.hud_key == :EnrollmentID
        add_index klass.table_name, [:EnrollmentID, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"
      end
      if column_names.include?('ProjectID') && ! klass.hud_key == :ProjectID
        add_index klass.table_name, [:ProjectID, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"
      end
    end

    HmisCsvTwentyTwenty::Loader::Loader.importable_files.each_value do |klass|
      column_names = klass.column_names
      add_column klass.table_name, :data_source_id, :integer, null: false, index: true
      add_column klass.table_name, :loaded_at, :datetime, null: false
      add_column klass.table_name, :loader_id, :integer, null: false, index: true

      add_index klass.table_name, [klass.hud_key, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"
      if column_names.include?('EnrollmentID') && ! klass.hud_key == :EnrollmentID
        add_index klass.table_name, [:EnrollmentID, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"
      end
      if column_names.include?('ProjectID') && ! klass.hud_key == :ProjectID
        add_index klass.table_name, [:ProjectID, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"
      end
    end

    create_table :hmis_csv_loader_logs do |t|
      t.integer :data_source_id, null: false, index: true
      t.integer :importer_log_id, index: true
      t.jsonb :summary
      t.string :status
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps index: true
      t.integer :upload_id
    end

    create_table :hmis_csv_import_validations do |t|
      t.integer :importer_log_id, null: false, index: true
      t.string :type, null: false, index: true
      t.string :source_id, null: false
      t.string :source_type, null: false
      t.string :status
    end
    add_index :hmis_csv_import_validations, [:source_type, :source_id], name: 'hmis_csv_validations-' + SecureRandom.alphanumeric(4)

    create_table :hmis_csv_load_errors do |t|
      t.integer :loader_log_id, null: false, index: true
      t.string :file_name, null: false
      t.string :message
      t.string :details
      t.string :source
    end

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
  end

  def down
    HmisCsvTwentyTwenty::Importer::Importer.importable_files.each do |_, klass|
      drop_table klass.table_name
    end
    HmisCsvTwentyTwenty::Loader::Loader.importable_files.each do |_, klass|
      drop_table klass.table_name
    end

    drop_table :hmis_csv_loader_logs
    drop_table :hmis_csv_load_errors

    drop_table :hmis_csv_importer_logs
    drop_table :hmis_csv_import_errors
    drop_table :hmis_csv_import_validations
  end
end
