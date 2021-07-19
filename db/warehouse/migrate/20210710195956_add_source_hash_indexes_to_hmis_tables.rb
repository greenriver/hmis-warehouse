class AddSourceHashIndexesToHmisTables < ActiveRecord::Migration[5.2]
  def change
    HmisCsvTwentyTwenty::Importer::Importer.importable_files.each do |_, source_klass|
      next if source_klass.hud_key == :ExportID

      klass = source_klass
      table_name = klass.table_name
      columns = [klass.hud_key, :importer_log_id, :data_source_id]
      name = table_name.gsub(/[^0-9a-z ]/i, '') + '_' + Digest::MD5.hexdigest(columns.to_s)[0..5]
      add_index klass.table_name, columns, name: name

    end
  end
end
