class AddMidMonthToMonthlyReports < ActiveRecord::Migration[5.2]
  def change
    add_column :warehouse_monthly_reports, :mid_month, :date
  end
end
