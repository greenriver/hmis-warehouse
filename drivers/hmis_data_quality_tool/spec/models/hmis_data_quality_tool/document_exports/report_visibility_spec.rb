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
    let(:report_definition_url) { 'hmis_data_quality_tool/warehouse_reports/reports' }

    it_behaves_like 'a document export limited to visible reports' do
      let(:report_attributes) { { question_names: [], report_name: report_class.untranslated_title } }

      it 'refuses a report the user ran when its report name is not the data quality tool' do
        other_report = report_class.create!(user_id: own_reports_user.id, question_names: [], report_name: 'Annual Performance Report')

        expect(export_for(own_reports_user, other_report.id).authorized?).to be(false)
      end
    end
  end
end
