FactoryGirl.define do
  factory :hud_client, class: 'GrdaWarehouse::Hud::Client' do
    sequence(:PersonalID, 10)
  end
end
