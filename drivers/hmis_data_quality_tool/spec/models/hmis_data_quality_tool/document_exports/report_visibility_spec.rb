###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

[
  HmisDataQualityTool::DocumentExports::ReportExport,
  HmisDataQualityTool::DocumentExports::ReportChartPdfExport,
  HmisDataQualityTool::DocumentExports::ReportExcelExport,
  HmisDataQualityTool::DocumentExports::ReportByClientExcelExport,
].each do |export_class|
  RSpec.describe export_class, type: :model do
    let(:report_class) { HmisDataQualityTool::Report }
    let(:report_definition_url) { report_class.url }

    it_behaves_like 'a document export limited to visible reports' do
      let(:report_attributes) { { question_names: [] } }
    end
  end
end
