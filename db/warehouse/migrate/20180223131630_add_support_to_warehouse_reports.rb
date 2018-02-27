class AddSupportToWarehouseReports < ActiveRecord::Migration
  def change
    add_column :warehouse_reports, :support, :json
  end
end
