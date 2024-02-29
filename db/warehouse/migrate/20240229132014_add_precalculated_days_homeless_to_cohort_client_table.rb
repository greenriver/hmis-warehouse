class AddPrecalculatedDaysHomelessToCohortClientTable < ActiveRecord::Migration[6.1]
  def change
    add_column :cohort_clients, :sheltered_days_homeless_last_three_years, :integer
    add_column :cohort_clients, :unsheltered_days_homeless_last_three_years, :integer
  end
end
