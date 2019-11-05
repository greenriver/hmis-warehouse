FactoryBot.define do
  factory :warehouse_client, class: 'GrdaWarehouse::WarehouseClient' do
    association :data_source, factory: :grda_warehouse_data_source
    association :destination, factory: :grda_warehouse_hud_client
    association :source, factory: :grda_warehouse_hud_client
    sequence(:id_in_source, 100)
  end

  factory :authoritative_warehouse_client, class: 'GrdaWarehouse::WarehouseClient' do
    association :data_source, factory: :grda_warehouse_data_source
    association :destination, factory: :grda_warehouse_hud_client
    association :source, factory: :authoritative_hud_client
    sequence(:id_in_source, 100)
  end
end
