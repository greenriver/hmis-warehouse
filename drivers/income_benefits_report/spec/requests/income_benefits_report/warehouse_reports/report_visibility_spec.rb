###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'IncomeBenefitsReport::WarehouseReports::Report visibility', type: :request do
  let(:report_class) { IncomeBenefitsReport::Report }
  let(:report_definition_url) { 'income_benefits_report/warehouse_reports/report' }
  let(:report_path) { ->(report) { income_benefits_report_warehouse_reports_report_path(report) } }

  it_behaves_like 'report member actions limited to visible reports' do
    let(:report_attributes) { { report_date_range: '2024-01-01..2024-01-31', comparison_date_range: '2023-01-01..2023-01-31' } }
  end
end
