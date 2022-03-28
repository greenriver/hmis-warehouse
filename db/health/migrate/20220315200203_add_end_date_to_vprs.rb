class AddEndDateToVprs < ActiveRecord::Migration[6.1]
  def change
    add_column :health_flexible_service_vprs, :end_date, :date
  end
end
