class AddImportFlag < ActiveRecord::Migration[5.2]
  def change
    HmisCsvTwentyTwenty::Importer::Importer.importable_files.each do |_, klass|
      add_column klass.table_name, :should_import, :boolean, default: true
    end
  end
end
