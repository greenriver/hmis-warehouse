class AddHomelessDaysInLastThreeYearsToProcessedClients < ActiveRecord::Migration
  def change
    add_column :warehouse_clients_processed, :days_homeless_last_three_years, :integer, index: true
  end
end
