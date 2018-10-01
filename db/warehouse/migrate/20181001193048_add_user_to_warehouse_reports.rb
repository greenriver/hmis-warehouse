class AddUserToWarehouseReports < ActiveRecord::Migration
  def change
    add_column :warehouse_reports, :user_id, :integer
  end
end
