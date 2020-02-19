class GoalAdjustments < ActiveRecord::Migration[5.2]
  def change
    (0..9).each do |i|
      add_column :health_goals, "action_step_#{i}", :string
      add_column :health_goals, "timeframe_#{i}", :string
    end
  end
end
