class AddDestinationClientIdToAprClients < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_apr_clients, :destination_client_id, :integer
  end
end
