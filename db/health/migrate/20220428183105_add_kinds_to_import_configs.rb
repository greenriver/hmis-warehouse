class AddKindsToImportConfigs < ActiveRecord::Migration[6.1]
  def change
    add_column :import_configs, :protocol, :string
    add_column :import_configs, :kind, :string
  end
end
