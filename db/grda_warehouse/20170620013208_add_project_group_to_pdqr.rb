class AddProjectGroupToPdqr < ActiveRecord::Migration
  def change
    add_column :project_data_quality, :project_group_id, :integer, index: true
  end
end
