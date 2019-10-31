class AddGoalDetailsToHealthGoals < ActiveRecord::Migration[4.2]
  def change
    add_column :health_goals, :goal_details, :text
  end
end
