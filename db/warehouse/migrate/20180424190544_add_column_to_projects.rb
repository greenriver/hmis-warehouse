class AddColumnToProjects < ActiveRecord::Migration[4.2]
  def change
    change_table :Project do |t|
      t.string :local_planning_group
    end
  end
end
