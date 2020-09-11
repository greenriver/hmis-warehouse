class AddHmisCsvLogsToImportLogs < ActiveRecord::Migration[5.2]
  def change
    add_reference :import_logs, :loader_log
    add_reference :import_logs, :importer_log
  end
end
