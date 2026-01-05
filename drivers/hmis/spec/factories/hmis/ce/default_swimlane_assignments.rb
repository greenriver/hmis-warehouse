# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_default_swimlane_assignment, class: 'Hmis::Ce::DefaultSwimlaneAssignment' do
    user { association :hmis_user }
    swimlane { association :hmis_workflow_definition_swimlane }
    association :owner, factory: :hmis_hud_project

    trait :for_unit_group do
      association :owner, factory: :hmis_unit_group
    end

    trait :for_organization do
      association :owner, factory: :hmis_hud_organization
    end

    trait :for_data_source do
      association :owner, factory: :hmis_data_source
    end
  end
end
