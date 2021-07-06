class AddDateAddedToCohortClients < ActiveRecord::Migration[5.2]
  def change
    add_column :cohort_clients, :date_added_to_cohort, :date
  end
end
