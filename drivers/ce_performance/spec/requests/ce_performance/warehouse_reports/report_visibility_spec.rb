###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CePerformance::WarehouseReports::Reports visibility', type: :request do
  let(:report_class) { CePerformance::Report }
  let(:report_definition_url) { 'ce_performance/warehouse_reports/reports' }
  let(:report_path) { ->(report) { ce_performance_warehouse_reports_report_path(report) } }

  it_behaves_like 'report member actions limited to visible reports'
end
