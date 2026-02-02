###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeSwimlaneUsersInput < Types::BaseInputObject
    description 'Mapping of a swimlane to user IDs'

    argument :swimlane_id, ID, required: true, description: 'Swimlane ID'
    argument :user_ids, [ID], required: true, description: 'Array of user IDs to assign to this swimlane'
  end

  class HmisSchema::CeDefaultContactsInput < Types::BaseInputObject
    description 'Input for creating CE default contacts'

    # If project_id is provided, assignments are project-specific. If null, contacts are tied to the current user's HMIS data source.
    # Later we could add unit_group_id and organization_id as optional inputs here.
    argument :project_id, ID, required: false, description: 'Project ID (if null, contacts are global)'

    # Array of swimlane-to-users mappings
    argument :contacts, [Types::HmisSchema::CeSwimlaneUsersInput], required: true, description: 'Swimlane to user ID mappings'
  end
end
