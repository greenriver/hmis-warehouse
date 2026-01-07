###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeDefaultAssignmentsBySwimlane < Types::BaseObject
    # object is an OpenStruct amalgamation of:
    # - Hmis::WorkflowDefinition::Swimlane, the swimlane
    # - [Hmis::Ce::DefaultSwimlaneAssignment], the assignments for this swimlane
    # This is a convenience helper for the backend to return assignments grouped by swimlane,
    # which is how the frontend displays them.

    field :swimlane, HmisSchema::CeSwimlane, null: false
    field :assignments, [HmisSchema::CeDefaultContact], null: false, description: 'Default assignments for this swimlane'
  end
end
