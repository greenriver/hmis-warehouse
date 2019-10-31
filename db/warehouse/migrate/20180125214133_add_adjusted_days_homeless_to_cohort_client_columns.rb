class AddAdjustedDaysHomelessToCohortClientColumns < ActiveRecord::Migration[4.2]
  def change
    add_column :cohort_clients, :adjusted_days_homeless, :integer
  end
end
