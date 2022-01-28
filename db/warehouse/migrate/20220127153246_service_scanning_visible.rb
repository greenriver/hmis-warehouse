class ServiceScanningVisible < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :service_register_visible, :boolean, null: false, default: false
  end
end
