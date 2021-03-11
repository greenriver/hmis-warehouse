FactoryBot.define do
  factory :vt_destination_data_source, class: 'GrdaWarehouse::DataSource' do
    name { 'Warehouse' }
    short_name { 'Warehouse' }
    source_type { nil }
    authoritative { false }
  end

  factory :vt_source_data_source, class: 'GrdaWarehouse::DataSource' do
    name { 'HMIS Vendor' }
    short_name { 'HV' }
    source_type { :s3 }
  end
end
