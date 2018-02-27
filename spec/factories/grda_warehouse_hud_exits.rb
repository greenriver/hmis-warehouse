FactoryGirl.define do
  factory :hud_exit, class: 'GrdaWarehouse::Hud::Exit' do
    sequence(:ExitID, 7)
    sequence(:ProjectEntryID, 1)
    sequence(:PersonalID, 10)
    sequence(:ExitDate) do |n|
      dates = [
        Date.today,
        15.days.ago,
        16.days.ago,
        17.days.ago,
        4.weeks.ago,
      ]
      dates[n%5].to_date
    end
  end
end
