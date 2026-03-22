# frozen_string_literal: true

FactoryBot.define do
  factory :grda_warehouse_import_csv_monitor, class: 'GrdaWarehouse::ImportCsvMonitor' do
    association :data_source, factory: :grda_warehouse_data_source
    csv_file_name { 'Client.csv' }
    count_increase_threshold { 50 }
    count_decrease_threshold { 50 }
    active { true }
  end
end
