###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

  factory :op_analytics_report, class: 'GrdaWarehouse::WarehouseReports::ReportDefinition' do
    report_group { 'Reports' }
    url { 'superset/warehouse_reports/reports' }
    name { 'Launch OP Analytics (Superset)' }
    description { 'An integration with the Apache Superset business intelligence tool.' }
  end

  factory :report_clients_dashboard, class: 'GrdaWarehouse::WarehouseReports::ReportDefinition' do
    report_group { 'Reports' }
    url { 'dashboards/clients' }
    name { 'All Clients' }
    description { 'Clients enrolled in homeless projects (ES, SH, SO, TH).' }
  end
end
