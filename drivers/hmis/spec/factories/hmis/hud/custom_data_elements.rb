###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_custom_data_element_definition, class: 'Hmis::Hud::CustomDataElementDefinition' do
    owner_type { 'Hmis::Hud::Project' }
    field_type { :string }
    repeats { false }
    sequence(:key) { |n| "customKey#{n + 123}" }
    label { 'Custom Field Label' }
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    DateCreated { Time.current }
    DateUpdated { Time.current }

    trait :primary_language do
      owner_type { 'Hmis::Hud::Client' }
      field_type { :string }
      key { 'primary-language' }
      label { 'Primary Language' }
      repeats { true }
    end

    trait :color do
      owner_type { 'Hmis::Hud::Client' }
      field_type { :string }
      key { 'color' }
      label { 'Color, and you can pick only one' }
      repeats { false }
    end

    trait :housing_preference do
      owner_type { 'Hmis::Hud::CustomAssessment' }
      field_type { :housing_preference }
      key { 'housing_preference' }
      label { 'Housing preference, can pick only one' }
      repeats { false }
    end

    factory :hmis_custom_data_element_definition_for_primary_language, traits: [:primary_language]

    factory :hmis_custom_data_element_definition_for_color, traits: [:color]

    factory :hmis_custom_data_element_definition_for_housing_preference, traits: [:housing_preference]
  end

  factory :hmis_custom_data_element, class: 'Hmis::Hud::CustomDataElement' do
    # Consumer must set owner and a value
    data_source { association :hmis_data_source }
    data_element_definition { association :hmis_custom_data_element_definition, data_source: data_source }
    user { association :hmis_hud_user, data_source: data_source }
    DateCreated { Time.current }
    DateUpdated { Time.current }

    after(:build) do |cde|
      provided_owner_type = cde.owner_type || cde.owner&.class&.sti_name
      likely_want_types_to_match = provided_owner_type != cde.data_element_definition.owner_type

      cde.data_element_definition.update_attribute(:owner_type, provided_owner_type) if likely_want_types_to_match
    end
  end
end
