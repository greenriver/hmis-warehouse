FactoryBot.define do
  factory :hud_event, class: 'GrdaWarehouse::Hud::Event' do
    sequence(:EventID, 12)
    sequence(:EnrollmentID, 1)
    sequence(:PersonalID, 10)
    sequence(:EventDate) do |n|
      dates = [
        Date.current,
        15.days.ago,
        16.days.ago,
        17.days.ago,
        4.weeks.ago,
      ]
      dates[n % 5].to_date
    end
    Event { 2 }
    ResultDate { 'Result' }
    sequence(:UserID, 5)
    DateCreated { Time.now }
    DateUpdated { Time.now }
    sequence(:ExportID, 500)
  end
end
