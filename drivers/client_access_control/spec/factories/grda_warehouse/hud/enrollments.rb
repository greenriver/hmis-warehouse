FactoryBot.define do
  factory :vt_enrollment, class: 'GrdaWarehouse::Hud::Enrollment' do
    association :data_source, factory: :vt_source_data_source
    sequence(:EnrollmentID, 1)
    sequence(:PersonalID, 10)
    sequence(:ProjectID, 100)
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
