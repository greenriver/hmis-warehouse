class AddDaysSinceCasMatchToProcessedClients < ActiveRecord::Migration
  def change
    add_column :warehouse_clients_processed, :days_since_cas_match, :integer
  end
end
