###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeProjectDefaultAssignment < Types::BaseObject
    # object is an OpenStruct amalgamation of:
    # - Hmis::WorkflowDefinition::Swimlane, the swimlane
    # - [Hmis::Ce::DefaultSwimlaneAssignment], the assignments for this swimlane

    field :swimlane, HmisSchema::CeSwimlane, null: false
    field :assignments, [HmisSchema::CeDefaultSwimlaneAssignment], null: false, description: 'Default assignments for this swimlane'
  end
end
