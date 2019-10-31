class AddServiceTypeToServiceHistory < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_client_service_history, :service_type, :integer
  end
end
