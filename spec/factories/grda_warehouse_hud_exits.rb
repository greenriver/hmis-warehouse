FactoryGirl.define do
  factory :hud_exit, class: 'GrdaWarehouse::Hud::Exit' do
    sequence(:ExitID, 7)
    sequence(:ProjectEntryID, 1)
    sequence(:PersonalID, 10)
  end
end
