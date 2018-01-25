class AddAdjustedDaysHomelessToCohortClientColumns < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :adjusted_days_homeless, :integer
  end
end
