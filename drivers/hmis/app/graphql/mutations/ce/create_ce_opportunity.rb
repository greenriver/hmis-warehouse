###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# TODO remove this mutation, deprecated
module Mutations
  class Ce::CreateCeOpportunity < CleanBaseMutation
    argument :project_id, ID, required: true
    argument :input, Types::HmisSchema::CeOpportunityInput, required: true
    field :opportunity, Types::HmisSchema::CeOpportunity, null: false

    def resolve(project_id:, input:) # TODO(#7529) - remove this mutation
      raise unless Hmis::Ce.configuration.enabled?

      project = Hmis::Hud::Project.viewable_by(current_user).find(project_id)
      access_denied! unless policy_for(project).can_manage_units?

      template = Hmis::WorkflowDefinition::Template.
        published.viewable_by(current_user).
        find_by(identifier: input.template_identifier)

      opportunity = nil
      project.with_lock do
        unit_group = project.unit_groups.last
        unit = Hmis::Unit.create!(name: input.name, project: project, user_id: current_user.id, unit_group: unit_group)
        opportunity = Hmis::Ce::Opportunity.new(project: project, unit: unit)
        opportunity.name = input.name
        opportunity.workflow_template = template
        opportunity.save!
      end
      { opportunity: opportunity }
    end
  end
end
