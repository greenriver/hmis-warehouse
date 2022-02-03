###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
