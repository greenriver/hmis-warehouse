FactoryBot.define do
  factory :grda_warehouse_data_source, class: 'GrdaWarehouse::DataSource' do
    name { 'Green River' }
    short_name { 'GR' }
    # association :client, factory: :grda_warehouse_hud_client
    source_type { nil }
    obey_consent { true }
  end

  factory :data_source_fixed_id, class: 'GrdaWarehouse::DataSource' do
    id { 1 }
    name { 'Green River' }
    short_name { 'GR' }
    # association :client, factory: :grda_warehouse_hud_client
    source_type { :sftp }
    obey_consent { true }
  end

  factory :source_data_source, class: 'GrdaWarehouse::DataSource' do
    name { 'HMIS Vendor' }
    short_name { 'HV' }
    # association :client, factory: :grda_warehouse_hud_client
    source_type { :sftp }
    obey_consent { true }
  end

  factory :destination_data_source, class: 'GrdaWarehouse::DataSource' do
    name { 'Warehouse' }
    short_name { 'Warehouse' }
    # association :client, factory: :grda_warehouse_hud_client
    source_type { nil }
    authoritative { false }
    obey_consent { true }
  end

  factory :authoritative_data_source, class: 'GrdaWarehouse::DataSource' do
    name { 'Authoritative' }
    short_name { 'A' }
    # association :client, factory: :grda_warehouse_hud_client
    source_type { nil }
    authoritative { true }
    authoritative_type { :youth }
    visible_in_window { true }
    obey_consent { true }
  end

  factory :non_window_data_source, class: 'GrdaWarehouse::DataSource' do
    name { 'Non-window' }
    short_name { 'NW' }
    # association :client, factory: :grda_warehouse_hud_client
    source_type { :sftp }
    visible_in_window { false }
    obey_consent { true }
  end

  factory :visible_data_source, class: 'GrdaWarehouse::DataSource' do
    name { 'Visible' }
    short_name { 'V' }
    # association :client, factory: :grda_warehouse_hud_client
    source_type { :sftp }
    visible_in_window { true }
    obey_consent { true }
  end

  factory :health_data_source, class: 'GrdaWarehouse::DataSource' do
    name { 'Health' }
    short_name { 'Health' }
    # association :client, factory: :grda_warehouse_hud_client
    source_type { nil }
    visible_in_window { true }
    obey_consent { true }
  end
end
