class AddIndexToPmClients < ActiveRecord::Migration[5.2]
  def change
    remove_index :pm_clients, :report_id
    remove_index :pm_clients, :client_id
    remove_index :pm_client_projects, :report_id
    remove_index :pm_client_projects, :client_id
    add_index :pm_client_projects, [:client_id, :report_id]
    add_index :pm_client_projects, [:for_question, :report_id, :period], name: :fq_r_id_p
  end
end
