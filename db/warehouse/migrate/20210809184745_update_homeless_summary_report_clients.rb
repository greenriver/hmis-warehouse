class UpdateHomelessSummaryReportClients < ActiveRecord::Migration[5.2]
  def up
    change_column_default :homeless_summary_report_clients, :spm_m7a1_c2, false
    change_column_default :homeless_summary_report_clients, :spm_m7a1_c3, false
    change_column_default :homeless_summary_report_clients, :spm_m7a1_c4, false
    change_column_default :homeless_summary_report_clients, :spm_m7b1_c2, false
    change_column_default :homeless_summary_report_clients, :spm_m7b1_c3, false
    change_column_default :homeless_summary_report_clients, :spm_m7b2_c2, false
    change_column_default :homeless_summary_report_clients, :spm_m7b2_c3, false
    add_column :homeless_summary_report_clients, :spm_exited_from_homeless_system, :boolean, default: false
  end
end
