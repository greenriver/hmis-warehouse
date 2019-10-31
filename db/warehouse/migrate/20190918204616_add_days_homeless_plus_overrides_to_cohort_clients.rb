class AddDaysHomelessPlusOverridesToCohortClients < ActiveRecord::Migration[4.2]
  def change
    add_column :cohort_clients, :days_homeless_plus_overrides, :integer
  end
end
