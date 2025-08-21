###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hud_custom_data_element, class: 'GrdaWarehouse::Hud::CustomDataElement' do
    sequence(:CustomDataElementID) { |n| "CDE-#{n.to_s.rjust(3, '0')}" }
    association :custom_data_element_definition, factory: :hud_custom_data_element_definition
    owner_type { 'GrdaWarehouse::Hud::Client' }
    sequence(:owner_id) { |n| n }
    value_string { 'test value' }
    data_element_definition_id { 0 }
    DateCreated { Time.current }
    DateUpdated { Time.current }
    sequence(:UserID) { |n| "USER-#{n}" }

    # Set CustomDataElementDefinitionID to match the associated definition
    before(:create) do |element, evaluator|
      element.CustomDataElementDefinitionID = evaluator.custom_data_element_definition.CustomDataElementDefinitionID if evaluator.custom_data_element_definition
    end

    trait :for_client do
      owner_type { 'GrdaWarehouse::Hud::Client' }
      association :custom_data_element_definition, factory: [:hud_custom_data_element_definition, :for_client]
    end
  end
end
