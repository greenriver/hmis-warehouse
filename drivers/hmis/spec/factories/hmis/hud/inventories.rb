FactoryBot.define do
  factory :hmis_hud_inventory, class: 'Hmis::Hud::Inventory' do
    data_source { association :hmis_data_source }
    sequence(:ProjectID, 200)
    sequence(:InventoryID, 300)
    sequence(:UserID, 100)
    HouseholdType { 1 }
    Availability { 1 }
    sequence(:UnitInventory, 100)
    sequence(:BedInventory, 100)
    InventoryStartDate { '2020-12-01' }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    # CoCCode { 'CA-001' }
  end
end
