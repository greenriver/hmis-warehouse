FactoryGirl.define do
  factory :warehouse_client, class: 'GrdaWarehouse::WarehouseClient' do
    association :destination, factory: :grda_warehouse_hud_client
    association :source, factory: :grda_warehouse_hud_client
    sequence(:id_in_source, 100)
  end
end