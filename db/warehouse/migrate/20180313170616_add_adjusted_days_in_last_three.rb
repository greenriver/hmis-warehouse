class AddAdjustedDaysInLastThree < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :adjusted_days_homeless_last_three_years, :integer, default: 0, null: false
  end
end
