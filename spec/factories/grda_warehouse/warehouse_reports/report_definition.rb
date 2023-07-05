FactoryBot.define do
  factory :touch_point_report, class: 'GrdaWarehouse::WarehouseReports::ReportDefinition' do
    report_group { 'Reports' }
    url { 'warehouse_reports/touch_point_exports' }
    name { 'TouchPoint Export' }
    description { '' }
  end

  factory :confidential_touch_point_report, class: 'GrdaWarehouse::WarehouseReports::ReportDefinition' do
    report_group { 'Reports' }
    url { 'warehouse_reports/confidential_touch_point_exports' }
    name { 'TouchPoint Export' }
    description { '' }
  end

  factory :core_demographics_report, class: 'GrdaWarehouse::WarehouseReports::ReportDefinition' do
    report_group { 'Reports' }
    url { 'core_demographics_report/warehouse_reports/core' }
    name { 'Core Demographics' }
    description { 'Summary data for client demographics across an arbitrary universe.' }
  end
end
