class DataSourceAvailableForServiceScanning < ActiveRecord::Migration[5.2]
  def change
    add_column :data_sources, :service_scannable, :boolean, default: false, null: false
  end
end
