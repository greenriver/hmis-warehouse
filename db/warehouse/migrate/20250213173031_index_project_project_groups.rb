###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class IndexProjectProjectGroups < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_index :project_project_groups, :project_group_id, where: 'deleted_at is NULL'
      add_index :project_project_groups, :project_id, where: 'deleted_at is NULL'
    end
  end
end
