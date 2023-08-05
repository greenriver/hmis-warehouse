###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_hud_enrollment, class: 'Hmis::Hud::Enrollment' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    project { association :hmis_hud_project, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    RelationshipToHoH { 1 }
    DateCreated { DateTime.current }
    DateUpdated { DateTime.current }
    HouseholdID { SecureRandom.uuid.gsub(/-/, '') }
    DisablingCondition { 99 }
    sequence(:EnrollmentID, 500)
    sequence(:EntryDate) do |n|
      dates = [
        3.weeks.ago,
        2.weeks.ago,
        1.week.ago,
        2.days.ago,
        Date.yesterday,
      ]
      dates[n % 5].to_date
    end
  end

  factory :hmis_hud_wip_enrollment, class: 'Hmis::Hud::Enrollment' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    project { association :hmis_hud_project, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    RelationshipToHoH { 1 }
    DateCreated { DateTime.current }
    DateUpdated { DateTime.current }
    HouseholdID { SecureRandom.uuid.gsub(/-/, '') }
    DisablingCondition { 99 }
    sequence(:EnrollmentID, 500)
    sequence(:EntryDate) do |n|
      dates = [
        3.weeks.ago,
        2.weeks.ago,
        1.week.ago,
        2.days.ago,
        Date.yesterday,
      ]
      dates[n % 5].to_date
    end
    after(:create, &:save_in_progress)
  end
end
