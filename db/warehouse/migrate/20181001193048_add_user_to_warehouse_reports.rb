class AddUserToWarehouseReports < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_reports, :user_id, :integer
  end
end
