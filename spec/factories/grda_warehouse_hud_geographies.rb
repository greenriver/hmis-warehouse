FactoryGirl.define do
  factory :hud_geography, class: 'GrdaWarehouse::Hud::Geography' do
    sequence(:ProjectID, 100)
    sequence(:GeographyID, 1)
  end
end
