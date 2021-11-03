class AddFileCountToImportConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :hmis_import_configs, :file_count, :integer, default: 1, null: false
  end
end
