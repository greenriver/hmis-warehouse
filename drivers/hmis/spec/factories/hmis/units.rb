###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_unit_type, class: 'Hmis::UnitType' do
    description { 'SRO' }
    bed_type { 13 }
    unit_size { 1 }
  end

  factory :hmis_active_range, class: 'Hmis::ActiveRange' do
    start_date { 1.month.ago }
    end_date { nil }
    user { association :hmis_user }
  end

  factory :hmis_unit, class: 'Hmis::Unit' do
    sequence(:name) { |n| "Unit #{n}" }
    user { association :hmis_user }
    project { association :hmis_hud_project }

    trait :in_unit_group do
      unit_group { association :hmis_unit_group, project: project }
    end

    factory :hmis_unit_in_group, traits: [:in_unit_group]
  end

  factory :hmis_unit_occupancy, class: 'Hmis::UnitOccupancy' do
    unit { association :hmis_unit }
    enrollment { association :hmis_hud_enrollment }
    occupancy_period { association :hmis_active_range }
    transient do
      start_date { 1.month.ago }
      end_date { nil }
    end
    after(:build) do |unit_occupancy, evaluator|
      unit_occupancy.occupancy_period.start_date = evaluator.start_date
      unit_occupancy.occupancy_period.end_date = evaluator.end_date
    end
  end
end
