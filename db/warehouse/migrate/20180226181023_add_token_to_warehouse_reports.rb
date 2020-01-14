class AddTokenToWarehouseReports < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_reports, :token, :string, index: true
  end
end
