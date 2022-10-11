FactoryBot.define do
  factory :grda_warehouse_hud_organization, class: 'GrdaWarehouse::Hud::Organization' do
    data_source_id { 1 } # :data_source_fixed_id
    sequence(:OrganizationID, 200)
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end
end
