FactoryGirl.define do
  factory :hud_inventory, class: 'GrdaWarehouse::Hud::Inventory' do
    sequence(:ProjectID, 100)
    sequence(:InventoryID, 1)
  end
end
