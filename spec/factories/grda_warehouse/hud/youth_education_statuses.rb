###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hud_youth_education_status, class: 'GrdaWarehouse::Hud::YouthEducationStatus' do
    sequence(:YouthEducationStatusID, 18)
    sequence(:EnrollmentID, 1)
    sequence(:PersonalID, 10)
    DataCollectionStage { 1 }
    sequence(:InformationDate) do |n|
      dates = [
        Date.current,
        15.days.ago,
        16.days.ago,
        17.days.ago,
        4.weeks.ago,
      ]
      dates[n % 5].to_date
    end
    sequence(:UserID, 5)
    DateCreated { Time.now }
    DateUpdated { Time.now }
    sequence(:ExportID, 500)
  end
end
