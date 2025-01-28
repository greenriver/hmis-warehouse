#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class CeOpportunityCreate < CleanBaseMutation
    argument :project_id, ID, required: true
    argument :input, Types::HmisSchema::CeOpportunityInput, required: true
    field :opportunity, Types::HmisSchema::CeOpportunity, null: false

    def resolve(project_id:, input:)
      raise unless Hmis::Ce.enabled?

      project = Hmis::Hud::Project.viewable_by(current_user).find(project_id)
      template = Hmis::WorkflowDefinition::Template.viewable_by(current_user).find(input.template_id)
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
