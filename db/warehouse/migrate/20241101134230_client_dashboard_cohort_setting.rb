class ClientDashboardCohortSetting < ActiveRecord::Migration[7.0]
  def change
    add_column :cohorts, :expose_inactive_on_client_dashboard, :boolean, default: false
  end
end
