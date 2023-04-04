###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_custom_service_category, class: 'Hmis::Hud::CustomServiceCategory' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    name { 'Financial Assistance' }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end

  factory :hmis_custom_service_type, class: 'Hmis::Hud::CustomServiceType' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    custom_service_category { association :hmis_custom_service_category, data_source: data_source }
    name { 'Rental Assistance' }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end

  factory :hmis_hud_custom_service_type, class: 'Hmis::Hud::CustomServiceType' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    custom_service_category { association :hmis_custom_service_category, data_source: data_source }
    name { 'Housing moving assistance' }
    hud_record_type { 141 }
    hud_type_provided { 9 }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end
end
