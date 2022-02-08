class IndexesTo2022Tables < ActiveRecord::Migration[6.1]
  def change
    spec_version = '2022'
    HmisCsvImporter::Importer::Importer.importable_files.each do |_, klass|
      add_index klass.table_name, :importer_log_id
    end

    HmisCsvImporter::Loader::Loader.loadable_files.each do |_, klass|
      add_index klass.table_name, :loader_id
    end
  end
end
