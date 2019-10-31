class RemoveIncorrectDaysSinceCasMatch < ActiveRecord::Migration[4.2]
  def change
    remove_column :warehouse_clients_processed, :days_since_cas_match, :integer
  end
end
