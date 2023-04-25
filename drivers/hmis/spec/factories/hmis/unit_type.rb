###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_unit_type, class: 'Hmis::UnitType' do
    bed_type { 13 }
    unit_size { 200 }
  end
end
