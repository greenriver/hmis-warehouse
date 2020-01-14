FactoryBot.define do
  factory :hud_organization, class: 'GrdaWarehouse::Hud::Organization' do
    sequence(:OrganizationID, 200)
    sequence(:OrganizationName, 200) { |n| "Organization #{n}" }
    association :data_source, factory: :grda_warehouse_data_source
  end
end
