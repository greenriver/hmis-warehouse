class AddIncomeTotalsToApr < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_apr_clients, :income_total_at_start, :integer
    add_column :hud_report_apr_clients, :income_total_at_annual_assessment, :integer
    add_column :hud_report_apr_clients, :income_total_at_exit, :integer
  end
end
