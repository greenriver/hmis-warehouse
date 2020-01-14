class ReplaceDaysSinceCasMatchWithDate < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_clients_processed, :last_cas_match_date, :datetime
  end
end
