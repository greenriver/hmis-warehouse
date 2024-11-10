class ProjectAccessGroupMembers < ActiveRecord::Migration[7.0]
  def up
    create_view :project_access_group_members, version: 1
  end

  def down
    drop_view :project_collection_members
  end
end
