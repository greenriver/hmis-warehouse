class AddTypeToImportConfig < ActiveRecord::Migration[7.0]
  def change
    add_column :import_configs, :type, :string
  end
end
