class AddIndexesToMonthlyReports < ActiveRecord::Migration
  def change
    add_index :warehouse_monthly_reports, [:type, :month, :year, :project_type], name: 'idx_monthly_rep_on_type_and_month_and_year_and_p_type'
  end
end
