FactoryBot.define do
  factory :hud_current_living_situation, class: 'GrdaWarehouse::Hud::CurrentLivingSituation' do
    sequence(:CurrentLivingSitID, 17)
    sequence(:EnrollmentID, 1)
    sequence(:PersonalID, 10)
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
    CurrentLivingSituation { 2 }
    sequence(:UserID, 5)
    DateCreated { Time.now }
    DateUpdated { Time.now }
    sequence(:ExportID, 500)
  end
end
