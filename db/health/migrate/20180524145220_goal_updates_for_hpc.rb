class GoalUpdatesForHpc < ActiveRecord::Migration
  def change
    add_column :health_goals, :problem, :text
    add_column :health_goals, :start_date, :date
    add_column :health_goals, :intervention, :text
    add_column :health_goals, :status, :string
    add_column :health_goals, :responsible_team_member_id, :integer
  end
end
