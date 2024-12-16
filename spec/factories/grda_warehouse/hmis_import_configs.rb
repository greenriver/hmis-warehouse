FactoryBot.define do
  factory :grda_warehouse_hmis_import_config, class: 'GrdaWarehouse::HmisImportConfig' do
    association :data_source, factory: :source_data_source
    active { true }
    s3_access_key_id { 'unknown' }
    s3_secret_access_key { 'unknown' }
  end
end
