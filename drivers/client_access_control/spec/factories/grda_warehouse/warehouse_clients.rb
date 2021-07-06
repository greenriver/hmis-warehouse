FactoryBot.define do
  factory :vt_warehouse_client, class: 'GrdaWarehouse::WarehouseClient' do
    association :data_source, factory: :source_data_source
    association :destination, factory: :destination_client
    association :source, factory: :source_client
    sequence(:id_in_source, 100)
  end
end
