class IndexImportTables < ActiveRecord::Migration[7.0]
  def tables
    [
      HmisCsvImporter::Loader::Loader.loadable_files,
      HmisCsvImporter::Importer::Importer.importable_files,
    ].flat_map(&:values).map(&:table_name).sort +
    (
      HmisCsvTwentyTwenty.expiring_loader_classes +
      HmisCsvTwentyTwenty.expiring_importer_classes +
      HmisCsvTwentyTwentyTwo.expiring_loader_classes +
      HmisCsvTwentyTwentyTwo.expiring_importer_classes
    ).map(&:table_name).sort
  end

  def change
    # NOTE: this may take a really long time, but we want to be sure it completes
    safety_assured do
      old_value = query_value('SHOW statement_timeout')
      execute "SET statement_timeout TO '0s'"

      tables.each do |table|
        add_index table, :data_source_id, if_not_exists: true
      end

      execute "SET statement_timeout TO #{quote(old_value)}"
    end
  end
end
