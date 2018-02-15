FactoryGirl.define do
  factory :hud_health_and_dv, class: 'GrdaWarehouse::Hud::HealthAndDv' do
    sequence(:HealthAndDVID, 7)
    sequence(:ProjectEntryID, 1)
    sequence(:PersonalID, 10)
  end
end
