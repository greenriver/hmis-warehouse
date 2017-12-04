FactoryGirl.define do
  factory :chronic_report, class: 'GrdaWarehouse::WarehouseReports::ReportDefinition' do
    name 'Potentially Chronic Clients'
    url = 'warehouse_reports/chronic'
    report_group = 'Operational Reports'
    description = 'Disabled clients who are currently homeless and have been in a project at least 12 of the last 36 months.<br />Calculated using HMIS data.'
  end
end
