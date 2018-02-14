FactoryGirl.define do
  factory :hud_geography, class: 'GrdaWarehouse::Hud::Site' do
    sequence(:ProjectID, 100)
    sequence(:SiteID, 1)
  end
end
