class AddSupportToWarehouseReports < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_reports, :support, :json
  end
end
