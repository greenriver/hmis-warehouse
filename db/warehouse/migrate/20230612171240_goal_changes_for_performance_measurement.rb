class GoalChangesForPerformanceMeasurement < ActiveRecord::Migration[6.1]
  def change
    add_column :performance_measurement_goals, :active, :boolean, default: true, null: false
    add_column :performance_measurement_goals, :label, :string
    add_column :performance_measurement_goals, :destination_so, :integer, default: 85, null: false
    add_column :performance_measurement_goals, :destination_homeless_plus, :integer, default: 85, null: false
    add_column :performance_measurement_goals, :destination_permanent, :integer, default: 85, null: false
  end
end
