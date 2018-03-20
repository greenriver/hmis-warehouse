FactoryGirl.define do
  factory :touch_point_report, class: 'GrdaWarehouse::WarehouseReports::ReportDefinition' do
      report_group 'Reports'
      url 'warehouse_reports/touch_point_exports'
      name 'TouchPoint Export'
      description ''
  end

  factory :confidential_touch_point_report, class: 'GrdaWarehouse::WarehouseReports::ReportDefinition' do
      report_group 'Reports'
      url 'warehouse_reports/confidential_touch_point_exports'
      name 'TouchPoint Export'
      description ''
  end
end
