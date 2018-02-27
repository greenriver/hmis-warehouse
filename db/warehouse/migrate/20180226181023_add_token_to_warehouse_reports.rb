class AddTokenToWarehouseReports < ActiveRecord::Migration
  def change
    add_column :warehouse_reports, :token, :string, index: true
  end
end
