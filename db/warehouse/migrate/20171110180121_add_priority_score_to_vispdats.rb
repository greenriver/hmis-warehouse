class AddPriorityScoreToVispdats < ActiveRecord::Migration
  def change
    add_column :vispdats, :priority_score, :integer
  end
end
