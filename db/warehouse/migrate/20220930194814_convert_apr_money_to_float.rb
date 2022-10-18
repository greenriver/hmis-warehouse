class ConvertAprMoneyToFloat < ActiveRecord::Migration[6.1]
  def up
    change_column :hud_report_apr_clients, :income_total_at_start, :float
    change_column :hud_report_apr_clients, :income_total_at_annual_assessment, :float
    change_column :hud_report_apr_clients, :income_total_at_exit, :float
  end
end
