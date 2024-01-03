class AddNewlyEnrolledToPathClients < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_path_clients, :newly_enrolled_client, :boolean, default: false
  end
end
