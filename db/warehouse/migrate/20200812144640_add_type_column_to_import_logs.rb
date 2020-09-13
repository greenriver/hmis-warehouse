class AddTypeColumnToImportLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :import_logs, :type, :string, default: 'GrdaWarehouse::ImportLog'
  end
end
