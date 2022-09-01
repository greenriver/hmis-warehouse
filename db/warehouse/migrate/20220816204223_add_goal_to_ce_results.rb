class AddGoalToCeResults < ActiveRecord::Migration[6.1]
  def change
    add_column :ce_performance_results, :goal, :integer
  end
end
