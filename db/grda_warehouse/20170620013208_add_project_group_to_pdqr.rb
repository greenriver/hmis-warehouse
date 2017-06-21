class AddProjectGroupToPdqr < ActiveRecord::Migration
  def change
    add_column :project_data_quality, :project_group_id, :integer, index: true
    change_column :project_data_quality, :project_id, :integer, null: true
  end
end
