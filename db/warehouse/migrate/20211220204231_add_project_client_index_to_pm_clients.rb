class AddProjectClientIndexToPmClients < ActiveRecord::Migration[5.2]
  def change
    add_index :pm_client_projects, [:client_id, :project_id, :report_id], name: :pm_clients_c_id_p_id_r_id
  end
end
