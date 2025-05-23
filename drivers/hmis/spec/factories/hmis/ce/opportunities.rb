# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_opportunity, class: 'Hmis::Ce::Opportunity' do
    sequence(:name) { |n| "Opportunity #{n}" }
    association(:project, factory: :hmis_hud_project)
    association(:workflow_template, factory: :hmis_workflow_definition_template)

    before(:create) do |instance|
      # Ensure data source consistency
      instance.workflow_template.data_source = instance.project.data_source if instance.project.data_source != instance.workflow_template.data_source
    end
  end
end
