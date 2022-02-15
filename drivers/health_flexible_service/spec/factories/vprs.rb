###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :vpr_patient, class: 'Health::Patient' do
    sequence(:id_in_source)
    patient_referral
    association :client, factory: :hud_client
    sequence(:medicaid_id)
  end

  factory :vpr, class: 'HealthFlexibleService::Vpr' do
    user
    association :patient, factory: :vpr_patient
    first_name { 'First' }
    sequence(:last_name) { |n| "Last#{n}" }
    dob { Date.current - rand(1000) }
  end

  trait :in_range_1 do
    service_1_added_on { Date.current }
  end

  trait :in_range_2 do
    service_2_added_on { Date.current }
  end

  trait :out_of_range_1 do
    service_1_added_on { Date.current - 1.year }
  end

  trait :out_of_range_2 do
    service_2_added_on { Date.current - 1.year }
  end

  trait :pre_tenancy_1 do
    service_1_category { 'Pre-Tenancy Supports: Individual Supports' }
    service_1_delivering_entity { 'PT Entity One' }
  end

  trait :pre_tenancy_2 do
    service_2_category { 'Pre-Tenancy Supports: Individual Supports' }
    service_2_delivering_entity { 'PT Entity Two' }
  end

  trait :nutrition_1 do
    service_1_category { 'Nutritional Sustaining Supports' }
    service_1_delivering_entity { 'Nutrition Entity One' }
  end

  trait :nutrition_2 do
    service_2_category { 'Nutritional Sustaining Supports' }
    service_2_delivering_entity { 'Nutrition Entity Two' }
  end
end
