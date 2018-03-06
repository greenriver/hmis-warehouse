class AddCohortClientsIneligible < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :ineligible, :boolean, default: false, null: false
  end
end
