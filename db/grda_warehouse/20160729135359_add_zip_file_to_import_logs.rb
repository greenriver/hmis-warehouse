class AddZipFileToImportLogs < ActiveRecord::Migration
  def change
    add_column :import_logs, :zip, :string
  end
end
