class AddDaysSinceCasMatchToProcessedClients < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_clients_processed, :days_since_cas_match, :integer
  end
end
