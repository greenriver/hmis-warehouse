###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeSwimlane < Types::BaseObject
    # object is a Hmis::WorkflowDefinition::Swimlane

    field :id, ID, null: false
    field :name, String, null: false
  end
end
