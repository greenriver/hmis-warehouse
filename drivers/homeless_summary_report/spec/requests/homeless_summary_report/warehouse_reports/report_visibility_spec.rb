###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HomelessSummaryReport::WarehouseReports::Reports visibility', type: :request do
  let(:report_class) { HomelessSummaryReport::Report }
  let(:report_definition_url) { 'homeless_summary_report/warehouse_reports/reports' }
  let(:report_path) { ->(report) { homeless_summary_report_warehouse_reports_report_path(report) } }

  it_behaves_like 'report member actions limited to visible reports' do
    let(:report_attributes) { { completed_at: Time.current } }
  end
end
