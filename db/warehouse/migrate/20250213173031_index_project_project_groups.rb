class IndexProjectProjectGroups < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_index :project_project_groups, :project_group_id, where: 'deleted_at is NULL'
      add_index :project_project_groups, :project_id, where: 'deleted_at is NULL'
    end
  end
end
