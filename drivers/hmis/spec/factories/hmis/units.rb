###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
    name { 'Unit A' }
    user { association :hmis_user }
    active_ranges { [association(:hmis_active_range)] }
  end

  factory :hmis_unit_occupancy, class: 'Hmis::UnitOccupancy' do
    unit { association :hmis_unit }
    enrollment { association :hmis_hud_enrollment }
    occupancy_period { association :hmis_active_range }
  end
end
