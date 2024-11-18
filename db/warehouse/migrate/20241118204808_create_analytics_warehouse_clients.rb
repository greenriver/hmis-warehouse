class CreateAnalyticsWarehouseClients < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.warehouse_clients'
  end
end
