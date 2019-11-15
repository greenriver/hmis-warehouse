FactoryBot.define do
  factory :grda_warehouse_data_source, class: 'GrdaWarehouse::DataSource' do
    name { 'Green River' }
    short_name { 'GR' }
    # association :client, factory: :grda_warehouse_hud_client
    source_type { nil }
  end

  factory :data_source_fixed_id, class: 'GrdaWarehouse::DataSource' do
    id { 1 }
    name { 'Green River' }
    short_name { 'GR' }
    # association :client, factory: :grda_warehouse_hud_client
    source_type { :sftp }
  end

  factory :source_data_source, class: 'GrdaWarehouse::DataSource' do
    name { 'HMIS Vendor' }
    short_name { 'HV' }
    # association :client, factory: :grda_warehouse_hud_client
    source_type { :sftp }
  end

  factory :destination_data_source, class: 'GrdaWarehouse::DataSource' do
    name { 'Warehouse' }
    short_name { 'Warehouse' }
    # association :client, factory: :grda_warehouse_hud_client
    source_type { nil }
    authoritative { false }
  end

  factory :authoritative_data_source, class: 'GrdaWarehouse::DataSource' do
    name { 'Authoritative' }
    short_name { 'A' }
    # association :client, factory: :grda_warehouse_hud_client
    source_type { nil }
    authoritative { true }
    authoritative_type { :youth }
    visible_in_window { true }
  end

  factory :non_window_data_source, class: 'GrdaWarehouse::DataSource' do
    name { 'Non-window' }
    short_name { 'NW' }
    # association :client, factory: :grda_warehouse_hud_client
    source_type { :sftp }
    visible_in_window { false }
  end

  factory :visible_data_source, class: 'GrdaWarehouse::DataSource' do
    name { 'Visible' }
    short_name { 'V' }
    # association :client, factory: :grda_warehouse_hud_client
    source_type { :sftp }
    visible_in_window { true }
  end
end
