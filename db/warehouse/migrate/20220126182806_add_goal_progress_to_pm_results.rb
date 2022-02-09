class AddGoalProgressToPmResults < ActiveRecord::Migration[5.2]
  def change
    add_column :pm_results, :goal_progress, :float
  end
end
