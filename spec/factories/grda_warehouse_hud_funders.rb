FactoryGirl.define do
  factory :hud_funder, class: 'GrdaWarehouse::Hud::Funder' do
    sequence(:ProjectID, 100)
    sequence(:FunderID, 1)
  end
end
