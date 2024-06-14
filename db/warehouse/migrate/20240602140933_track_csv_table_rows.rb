class TrackCsvTableRows < ActiveRecord::Migration[7.0]
  def tables
    [
      HmisCsvImporter::Loader::Loader.loadable_files,
      HmisCsvImporter::Importer::Importer.importable_files,
    ].flat_map(&:values).map(&:table_name).sort
  end

  def change
    tables.each do |table|
      next if table =~ /_exports\z/

      add_column table, :expired, :boolean
    end
  end
end
