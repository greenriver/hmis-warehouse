class AddIndexesToMonthlyReports < ActiveRecord::Migration
  def change
    add_index :warehouse_monthly_reports, [:type, :month, :year]
  end
end
