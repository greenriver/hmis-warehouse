###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::WorkflowDefinitionTemplate < Types::BaseEnum
    description 'Workflow Definition Templates'

    # todo @martha - seems to be working well in application, but something is breaking in tests, needs to move to pick list type.
    # but then it can't be a filter type
    Hmis::WorkflowDefinition::Template.published.
      or(Hmis::WorkflowDefinition::Template.retired).
      group_by(&:identifier).map do |identifier, templates|
      description = templates.max_by(&:updated_at).name
      value identifier, description
    end
  end
end
