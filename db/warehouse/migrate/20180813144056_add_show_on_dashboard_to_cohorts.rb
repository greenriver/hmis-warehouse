class AddShowOnDashboardToCohorts < ActiveRecord::Migration
  def change
    add_column :cohorts, :show_on_client_dashboard, :boolean, default: true, null: false
  end
end
