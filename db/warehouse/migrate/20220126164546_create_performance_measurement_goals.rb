class CreatePerformanceMeasurementGoals < ActiveRecord::Migration[5.2]
  def change
    create_table :performance_measurement_goals do |t|
      t.string :coc_code, null: false
      {
        people: 3,
        capacity: 90,
        time_time: 90,
        time_stay: 60,
        time_move_in: 30,
        destination: 85,
        recidivism_6_months: 15,
        recidivism_24_months: 25,
        income: 3,
      }.each do |column, default|
        t.integer column, default: default, null: false
      end
      t.timestamps null: false
      t.datetime :deleted_at
    end
  end
end
