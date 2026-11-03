###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'LongitudinalSpm::WarehouseReports::Reports visibility', type: :request do
  let(:report_class) { LongitudinalSpm::Report }
  let(:report_definition_url) { 'longitudinal_spm/warehouse_reports/reports' }
  let(:report_path) { ->(report) { longitudinal_spm_warehouse_reports_report_path(report) } }

  it_behaves_like 'report member actions limited to visible reports'
end
