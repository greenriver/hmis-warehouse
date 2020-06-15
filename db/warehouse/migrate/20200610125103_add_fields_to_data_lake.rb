class AddFieldsToDataLake < ActiveRecord::Migration[5.2]
  def up
    HmisCsvTwentyTwenty::Importer::Importer.importable_files.each_value do |klass|
      add_column klass.table_name, :data_source_id, :integer, null: false, index: true
      add_column klass.table_name, :pre_processed_at, :datetime, null: false
      add_column klass.table_name, :processed_as, :string
      add_column klass.table_name, :source_id, :integer, null: false
      add_column klass.table_name, :source_type, :integer, null: false

      add_index klass.table_name, [:source_type, :source_id], name: klass.table_name + '-' + SecureRandom.alphanumeric(4)
    end

    HmisCsvTwentyTwenty::Loader::Loader.importable_files.each_value do |klass|
      add_column klass.table_name, :data_source_id, :integer, null: false, index: true
      add_column klass.table_name, :loaded_at, :datetime, null: false
      add_column klass.table_name, :loader_id, :integer, null: false, index: true
    end
  end

  def down
    HmisCsvTwentyTwenty::Importer::Importer.importable_files.each_value do |klass|
      drop_table klass.table_name
    end

   HmisCsvTwentyTwenty::Loader::Loader.importable_files.each_value do |klass|
      drop_table klass.table_name
    end
  end
end
