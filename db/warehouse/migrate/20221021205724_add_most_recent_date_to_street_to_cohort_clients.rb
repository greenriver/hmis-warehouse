class AddMostRecentDateToStreetToCohortClients < ActiveRecord::Migration[6.1]
  def change
    add_column :cohort_clients, :most_recent_date_to_street, :date
  end
end
