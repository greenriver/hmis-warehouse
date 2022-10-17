FactoryBot.define do
  factory :hmis_hud_enrollment, class: 'Hmis::Hud::Enrollment' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    project { association :hmis_hud_project, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    RelationshipToHoH { 1 }
    HouseholdID { SecureRandom.uuid.gsub(/-/, '') }
    sequence(:EnrollmentID, 1)
    sequence(:EntryDate) do |n|
      dates = [
        Date.current,
        8.weeks.ago,
        6.weeks.ago,
        4.weeks.ago,
        2.weeks.ago,
      ]
      dates[n % 5].to_date
    end
  end
end
