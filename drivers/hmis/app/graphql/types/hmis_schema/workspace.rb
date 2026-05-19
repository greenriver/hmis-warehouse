###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Workspace < Types::BaseObject
    skip_activity_log

    field :id, ID, null: false
    field :name, String, null: false
    field :slug, String, null: false
    field :project_group_id, ID, null: false, method: :hmis_project_group_id
  end
end
