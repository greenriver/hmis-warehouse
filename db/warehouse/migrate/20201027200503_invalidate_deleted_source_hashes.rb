class InvalidateDeletedSourceHashes < ActiveRecord::Migration[5.2]
  def up
    HmisCsvTwentyTwenty::Importer::Importer.importable_files_map.each_value do |name|
      klass = "GrdaWarehouse::Hud::#{name}".constantize
      klass.only_deleted.update_all(source_hash: nil) if klass.paranoid?
    end
  end
end
