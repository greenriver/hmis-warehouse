class AddDaysHomelessPlusOverridesToCohortClients < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :days_homeless_plus_overrides, :integer
  end
end
