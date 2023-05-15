###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_custom_data_element_definition, class: 'Hmis::Hud::CustomDataElementDefinition' do
    owner_type { 'Hmis::Hud::Project' }
    field_type { :string }
    repeats { false }
    key { 'customKey' }
    label { 'Custom Field Label' }
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    DateCreated { Date.current }
    DateUpdated { Date.current }
  end

  factory :hmis_custom_data_element, class: 'Hmis::Hud::CustomDataElement' do
    # Consumer must set owner and a value
    data_source { association :hmis_data_source }
    data_element_definition { association :hmis_custom_data_element_definition, data_source: data_source }
    user { association :hmis_hud_user, data_source: data_source }
    DateCreated { Date.current }
    DateUpdated { Date.current }
  end
end
