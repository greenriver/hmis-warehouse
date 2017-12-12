FactoryGirl.define do
  factory :chronic_report, class: 'GrdaWarehouse::WarehouseReports::ChronicReport' do
      parameters { {} }
      data []
  end
end
