###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PerformanceMetrics::WarehouseReports::Reports visibility', type: :request do
  let(:report_class) { PerformanceMetrics::Report }
  let(:report_definition_url) { 'performance_metrics/warehouse_reports/reports' }
  let(:report_path) { ->(report) { performance_metrics_warehouse_reports_report_path(report) } }

  it_behaves_like 'report member actions limited to visible reports'
end
