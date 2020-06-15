class AddDirtyToImportTables < ActiveRecord::Migration[5.2]
  def change
    HmisCsvTwentyTwenty::Importer::Importer.importable_files.each_value do |klass|
      add_column klass.table_name, :dirty_at, :timestamp, index: true
      add_column klass.table_name, :clean_at, :timestamp, index: true
      add_column klass.table_name, :importer_log_id, :integer, index: true, null: false
    end
  end
end
