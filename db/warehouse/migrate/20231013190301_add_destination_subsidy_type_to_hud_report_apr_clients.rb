class AddDestinationSubsidyTypeToHudReportAprClients < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_apr_clients, :exit_destination_subsidy_type, :integer
  end
end
