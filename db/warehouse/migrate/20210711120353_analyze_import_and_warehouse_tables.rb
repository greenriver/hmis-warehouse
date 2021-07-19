class AnalyzeImportAndWarehouseTables < ActiveRecord::Migration[5.2]
  def up
    HmisCsvTwentyTwenty::Importer::Importer.importable_files.each do |_, source_klass|
      klass = source_klass
      table_name = klass.quoted_table_name
      klass.connection.execute("ANALYZE #{table_name}")

      klass = source_klass.warehouse_class
      table_name = klass.quoted_table_name
      klass.connection.execute("ANALYZE #{table_name}")
    end
  end
end
