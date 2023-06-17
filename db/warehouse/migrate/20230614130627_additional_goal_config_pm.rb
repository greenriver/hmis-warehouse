class AdditionalGoalConfigPm < ActiveRecord::Migration[6.1]
  def change
    add_column :performance_measurement_goals, :time_time_homeless_and_ph, :integer, default: 90, null: false
  end
end
