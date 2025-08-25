###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hud_custom_data_element_definition, class: 'GrdaWarehouse::Hud::CustomDataElementDefinition' do
    sequence(:CustomDataElementDefinitionID) { |n| "CDE-DEF-#{n.to_s.rjust(3, '0')}" }
    owner_type { 'GrdaWarehouse::Hud::Client' }
    field_type { 'string' }
    sequence(:key) { |n| "test_field_#{n}" }
    sequence(:label) { |n| "Test Custom Field #{n}" }
    repeats { false }
    DateCreated { Time.current }
    DateUpdated { Time.current }
    sequence(:UserID) { |n| "USER-#{n}" }

    trait :for_client do
      owner_type { 'GrdaWarehouse::Hud::Client' }
    end
  end
end
