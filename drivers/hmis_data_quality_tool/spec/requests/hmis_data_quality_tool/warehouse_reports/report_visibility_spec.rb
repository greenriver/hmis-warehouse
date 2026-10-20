###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HmisDataQualityTool::WarehouseReports::Reports visibility', type: :request do
  let(:report_class) { HmisDataQualityTool::Report }
  let(:report_definition_url) { 'hmis_data_quality_tool/warehouse_reports/reports' }
  let(:report_path) { ->(report) { hmis_data_quality_tool_warehouse_reports_report_path(report) } }

  it_behaves_like 'report member actions limited to visible reports' do
    # The controller's report_scope also filters on report_name.
    let(:report_attributes) { { report_name: HmisDataQualityTool::Report.untranslated_title, question_names: [] } }
  end
end
