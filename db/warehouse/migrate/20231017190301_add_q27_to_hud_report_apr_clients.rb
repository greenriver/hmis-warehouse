class AddQ27ToHudReportAprClients < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_apr_clients, :current_school_attend_at_entry, :integer
    add_column :hud_report_apr_clients, :most_recent_ed_status_at_entry, :integer
    add_column :hud_report_apr_clients, :current_ed_status_at_entry, :integer

    add_column :hud_report_apr_clients, :current_school_attend_at_exit, :integer
    add_column :hud_report_apr_clients, :most_recent_ed_status_at_exit, :integer
    add_column :hud_report_apr_clients, :current_ed_status_at_exit, :integer
  end
end
