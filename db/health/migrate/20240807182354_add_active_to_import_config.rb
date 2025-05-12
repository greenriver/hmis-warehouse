class AddActiveToImportConfig < ActiveRecord::Migration[7.0]
  def change
    add_column :import_configs, :active, :boolean, default: false
  end
end
