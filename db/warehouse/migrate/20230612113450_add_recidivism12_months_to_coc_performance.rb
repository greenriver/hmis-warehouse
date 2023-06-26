class AddRecidivism12MonthsToCoCPerformance < ActiveRecord::Migration[6.1]
  def change
    add_column :performance_measurement_goals, :recidivism_12_months, :integer, default: 20, null: false
  end
end
