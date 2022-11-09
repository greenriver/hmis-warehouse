class AddDestinationClientIdToPathReportClients < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_path_clients, :destination_client_id, :integer
  end
end
