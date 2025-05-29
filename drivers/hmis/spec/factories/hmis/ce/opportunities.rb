# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_opportunity, class: 'Hmis::Ce::Opportunity' do
    sequence(:name) { |n| "Opportunity #{n}" }
    association(:project, factory: :hmis_hud_project)
    association(:workflow_template, factory: :hmis_workflow_definition_template)
    after(:build) do |opportunity, _evaluator|
      # If owner not specified, build a unit in the same project
      opportunity.owner ||= build(:hmis_unit, project: opportunity.project)

      # Ensure data source consistency. FactoryBot unfortunately doesn't expose a way to know which of these was
      # passed as an argument to the factory, and which was generated from the default associations.
      # Since we don't know, we just pick one -- the project -- but this does mean that if workflow_template is
      # provided and NOT project, the factory won't work correctly.
      opportunity.workflow_template.data_source = opportunity.project.data_source if opportunity.project.data_source != opportunity.workflow_template.data_source
    end
  end
end
