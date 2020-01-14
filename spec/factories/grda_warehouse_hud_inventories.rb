FactoryBot.define do
  factory :hud_inventory, class: 'GrdaWarehouse::Hud::Inventory' do
    association :data_source, factory: :grda_warehouse_data_source
    sequence(:ProjectID, 100)
    sequence(:InventoryID, 1)
  end
end
