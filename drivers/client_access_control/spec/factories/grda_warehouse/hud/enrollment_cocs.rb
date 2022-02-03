###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :vt_enrollment_coc, class: 'GrdaWarehouse::Hud::EnrollmentCoc' do
    association :data_source, factory: :vt_source_data_source
    sequence(:EnrollmentCoCID, 7)
    sequence(:EnrollmentID, 1)
    sequence(:ProjectID, 100)
    sequence(:PersonalID, 10)
  end
end
