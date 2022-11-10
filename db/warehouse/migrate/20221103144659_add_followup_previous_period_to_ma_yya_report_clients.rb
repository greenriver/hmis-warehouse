class AddFollowupPreviousPeriodToMaYyaReportClients < ActiveRecord::Migration[6.1]
  def change
    add_column :ma_yya_report_clients, :followup_previous_period, :boolean
  end
end
