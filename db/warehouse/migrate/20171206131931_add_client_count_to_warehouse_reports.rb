class AddClientCountToWarehouseReports < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_reports, :client_count, :integer
  end
end
