# frozen_string_literal: true

class UpdateHmisGroupViewableEntityProjectsToVersion3 < ActiveRecord::Migration[7.1]
  def change
    replace_view :hmis_group_viewable_entity_projects, version: 3, revert_to_version: 2
  end
end
