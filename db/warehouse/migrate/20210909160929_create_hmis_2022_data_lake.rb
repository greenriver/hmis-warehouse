class CreateHmis2022DataLake < ActiveRecord::Migration[5.2]
  def up
    spec_version = '2022'

    HmisCsvImporter::Importer::Importer.importable_files.each do |_, klass|
      klass.hmis_table_create!(version: spec_version, constraints: false)
      klass.hmis_table_create_indices!(version: spec_version)
    end
    HmisCsvImporter::Loader::Loader.importable_files.each do |_, klass|
      klass.hmis_table_create!(version: spec_version, constraints: false, types: false)
      klass.hmis_table_create_indices!(version: spec_version)
    end

    HmisCsvImporter::Importer::Importer.importable_files.each_value do |klass|
      column_names = klass.column_names
      add_column klass.table_name, :data_source_id, :integer, null: false, index: true
      add_column klass.table_name, :importer_log_id, :integer, index: true, null: false
      add_column klass.table_name, :pre_processed_at, :datetime, null: false
      add_column klass.table_name, :source_hash, :string
      add_column klass.table_name, :source_id, :integer, null: false
      add_column klass.table_name, :source_type, :string, null: false

      add_column klass.table_name, :dirty_at, :timestamp, index: true
      add_column klass.table_name, :clean_at, :timestamp, index: true

      add_column klass.table_name, :should_import, :boolean, default: true

      add_index klass.table_name, [:source_type, :source_id], name: klass.table_name + '-' + SecureRandom.alphanumeric(4)
      add_index klass.table_name, [klass.hud_key, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"

      if column_names.include?('EnrollmentID') && ! klass.hud_key == :EnrollmentID
        add_index klass.table_name, [:EnrollmentID, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"
      end
      if column_names.include?('ProjectID') && ! klass.hud_key == :ProjectID
        add_index klass.table_name, [:ProjectID, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"
      end
    end

    HmisCsvImporter::Loader::Loader.importable_files.each_value do |klass|
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

      HmisCsvImporter::Aggregated::Enrollment.migrate_to_unversioned
      HmisCsvImporter::Aggregated::Exit.migrate_to_unversioned
    end
  end

  def down
    HmisCsvImporter::Importer::Importer.importable_files.each do |_, klass|
      drop_table klass.table_name
    end

    HmisCsvImporter::Loader::Loader.importable_files.each do |_, klass|
      drop_table klass.table_name
    end
  end
end
