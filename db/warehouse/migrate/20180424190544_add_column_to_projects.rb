class AddColumnToProjects < ActiveRecord::Migration
  def change
    change_table :Project do |t|
      t.string :local_planning_group
    end
  end
end
