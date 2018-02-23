FactoryGirl.define do
  factory :hud_exit, class: 'GrdaWarehouse::Hud::Exit' do
    sequence(:ExitID, 7)
    sequence(:ProjectEntryID, 1)
    sequence(:PersonalID, 10)
    sequence(:ExitDate) do |n|
      dates = [
        Date.today,
        1.days.ago,
        3.days.ago,
        2.weeks.ago,
        4.weeks.ago,
      ]
      dates[n%5].to_date
    end
  end
end
