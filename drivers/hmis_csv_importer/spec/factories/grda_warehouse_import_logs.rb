# frozen_string_literal: true

FactoryBot.define do
  factory :grda_warehouse_import_log, class: 'GrdaWarehouse::ImportLog' do
    association :data_source, factory: :grda_warehouse_data_source
    files { 'test.csv' }
    summary { 'Test import' }
    completed_at { Time.current }
    type { 'GrdaWarehouse::ImportLog' }
  end
end
