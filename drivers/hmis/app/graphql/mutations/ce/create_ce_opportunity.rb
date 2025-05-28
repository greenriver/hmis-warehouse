###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class Ce::CreateCeOpportunity < CleanBaseMutation
    argument :project_id, ID, required: true
    argument :input, Types::HmisSchema::CeOpportunityInput, required: true
    field :opportunity, Types::HmisSchema::CeOpportunity, null: false

    def resolve(project_id:, input:) # TODO(#7529) - remove this mutation
      raise unless Hmis::Ce.configuration.enabled?

      project = Hmis::Hud::Project.viewable_by(current_user).find(project_id)
      access_denied! unless current_permission?(permission: :can_manage_units, entity: project)

      template = Hmis::WorkflowDefinition::Template.
        published.viewable_by(current_user).
        find_by(identifier: input.template_identifier)

      opportunity = nil
      project.with_lock do
        opportunity = Hmis::Ce::Opportunity.new(project: project)
        opportunity.name = input.name
        opportunity.workflow_template = template
        opportunity.save!
      end
      { opportunity: opportunity }
    end
  end
end
