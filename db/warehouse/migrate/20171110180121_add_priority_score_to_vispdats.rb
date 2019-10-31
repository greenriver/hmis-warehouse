class AddPriorityScoreToVispdats < ActiveRecord::Migration[4.2]
  def change
    add_column :vispdats, :priority_score, :integer
  end
end
