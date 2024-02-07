class UpdateHmisGroupViewableEntityProjectsToVersion2 < ActiveRecord::Migration[6.1]
  def change
    update_view :hmis_group_viewable_entity_projects, version: 2, revert_to_version: 1
  end
end
