class AddProjectIdToAprClients < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_apr_clients, :project_id, :integer
  end
end
