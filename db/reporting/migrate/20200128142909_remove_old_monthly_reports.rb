class RemoveOldMonthlyReports < ActiveRecord::Migration[5.2]
  def up
    drop_table :warehouse_monthly_reports
  end
end
