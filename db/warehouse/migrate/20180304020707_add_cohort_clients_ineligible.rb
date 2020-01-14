class AddCohortClientsIneligible < ActiveRecord::Migration[4.2]
  def change
    add_column :cohort_clients, :ineligible, :boolean, default: false, null: false
  end
end
