###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ProjectAccessGroupMembers < ActiveRecord::Migration[7.0]
  def up
    create_view :project_access_group_members, version: 1
  end

  def down
    drop_view :project_collection_members
  end
end
