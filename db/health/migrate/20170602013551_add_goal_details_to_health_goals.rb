class AddGoalDetailsToHealthGoals < ActiveRecord::Migration
  def change
    add_column :health_goals, :goal_details, :text
  end
end
