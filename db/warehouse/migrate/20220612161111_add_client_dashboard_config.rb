class AddClientDashboardConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :configs, :client_dashboard, :string, default: :default, null: false
  end
end
