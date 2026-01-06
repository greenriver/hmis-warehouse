###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::SwimlaneAssignmentInput < Types::BaseInputObject
    description 'Mapping of a swimlane to user IDs'

    argument :swimlane_id, ID, required: true, description: 'Swimlane ID'
    argument :user_ids, [ID], required: true, description: 'Array of user IDs to assign to this swimlane'
  end

  class HmisSchema::CeDefaultSwimlaneAssignmentInput < Types::BaseInputObject
    description 'Input for creating CE default swimlane assignments'

    # If project_id is provided, assignments are project-specific. If null, assignments are global (tied to the current user's HMIS data source).
    # Later we can add unit_group_id and organization_id as optional inputs here, but for now the UI only allows creating global and project-level assignments.
    argument :project_id, ID, required: false, description: 'Project ID (if null, assignments are global)'

    # Array of swimlane-to-users mappings
    argument :assignments, [Types::HmisSchema::SwimlaneAssignmentInput], required: true, description: 'Swimlane to user ID mappings'
  end
end
