class AddProjectTypesToPmClients < ActiveRecord::Migration[5.2]
  def change
    add_column :pm_clients, :reporting_served_on_pit_date_sheltered, :boolean, default: false, null: false
    add_column :pm_clients, :comparison_served_on_pit_date_sheltered, :boolean, default: false, null: false
    add_column :pm_clients, :reporting_served_on_pit_date_unsheltered, :boolean, default: false, null: false
    add_column :pm_clients, :comparison_served_on_pit_date_unsheltered, :boolean, default: false, null: false
  end
end
