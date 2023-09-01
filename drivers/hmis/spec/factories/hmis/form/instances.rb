###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_form_instance, class: 'Hmis::Form::Instance' do
    entity { association :hmis_hud_project }
    definition { association :hmis_form_definition }
    active { true }
    system { false }
    transient do
      role { nil }
    end
    after(:create) do |instance, evaluator|
      instance.definition.update(role: evaluator.role) if evaluator.role.present?
      instance.definition.update(identifier: evaluator.definition_identifier) if evaluator.definition_identifier.present?
    end
  end
end
