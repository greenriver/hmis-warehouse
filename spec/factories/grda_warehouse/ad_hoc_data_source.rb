FactoryBot.define do
  factory :ad_hoc_data_source, class: 'GrdaWarehouse::AdHocDataSource' do
    name { 'Ad-Hoc Data Source' }
    short_name { 'AH' }
  end
end
