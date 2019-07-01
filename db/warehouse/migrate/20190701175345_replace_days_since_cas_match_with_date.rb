class ReplaceDaysSinceCasMatchWithDate < ActiveRecord::Migration
  def change
    add_column :warehouse_clients_processed, :last_cas_match_date, :datetime
  end
end
