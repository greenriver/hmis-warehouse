class AddCoCConfigToCoCPerformance < ActiveRecord::Migration[6.1]
  def change
    add_column :performance_measurement_goals, :always_run_for_coc, :boolean, default: false
  end
end
