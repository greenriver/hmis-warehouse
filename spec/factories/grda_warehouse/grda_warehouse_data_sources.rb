FactoryGirl.define do
  factory :grda_warehouse_data_source, class: 'GrdaWarehouse::DataSource' do
    name 'Green River'
    short_name 'GR'
    # association :client, factory: :grda_warehouse_hud_client
    source_type nil
  end
end
