class AddZipFileToImportLogs < ActiveRecord::Migration[4.2]
  def change
    add_column :import_logs, :zip, :string
  end
end
