class AddProjectTypesToPmClients < ActiveRecord::Migration[5.2]
  def change
    add_column :pm_clients, :reporting_served_on_pit_date_sheltered, :integer, array: true
    add_column :pm_clients, :comparison_served_on_pit_date_sheltered, :integer, array: true
    add_column :pm_clients, :reporting_served_on_pit_date_usheltered, :integer, array: true
    add_column :pm_clients, :comparison_served_on_pit_date_unsheltered, :integer, array: true
  end
end
