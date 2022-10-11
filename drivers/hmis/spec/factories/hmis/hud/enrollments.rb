FactoryBot.define do
  factory :hmis_hud_enrollment, class: 'Hmis::Hud::Enrollment' do
    association :data_source, factory: :hmis_data_source
    association :project, factory: :hmis_hud_project
    association :client, factory: :hmis_hud_client
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
