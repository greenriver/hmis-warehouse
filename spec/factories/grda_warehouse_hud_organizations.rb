FactoryGirl.define do
  factory :hud_organization, class: 'GrdaWarehouse::Hud::Organization' do
    sequence(:OrganizationID, 200)
    sequence(:OrganizationName, 200) {|n| "Organization #{n}"}
  end
end
