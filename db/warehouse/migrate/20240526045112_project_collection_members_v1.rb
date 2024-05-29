class ProjectCollectionMembersV1 < ActiveRecord::Migration[6.1]
  def up
    create_view :project_collection_members, version: 1
  end

  def down
    drop_view :project_collection_members
  end
end
