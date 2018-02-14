FactoryGirl.define do
  factory :hud_affiliation, class: 'GrdaWarehouse::Hud::Affiliation' do
    sequence(:ProjectID, 100)
    sequence(:AffiliationID, 1)
  end
end
