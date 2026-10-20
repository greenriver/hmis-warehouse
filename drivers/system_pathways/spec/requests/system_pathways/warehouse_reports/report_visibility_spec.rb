###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SystemPathways::WarehouseReports::Reports visibility', type: :request do
  let(:report_class) { SystemPathways::Report }
  let(:report_definition_url) { 'system_pathways/warehouse_reports/reports' }
  let(:report_path) { ->(report) { system_pathways_warehouse_reports_report_path(report) } }

  it_behaves_like 'report member actions limited to visible reports'

  describe 'other single-report actions' do
    include_context 'report visibility users'

    before { sign_in(own_reports_user) }

    it 'returns not found for details on a report run by another user' do
      get details_system_pathways_warehouse_reports_report_path(others_report, node: 'Emergency Shelter')

      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for chart data on a report run by another user' do
      get chart_data_system_pathways_warehouse_reports_report_path(others_report, chart: 'equity', format: :json)

      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found when reloading a report run by another user' do
      post reload_from_csv_system_pathways_warehouse_reports_report_path(others_report)

      expect(response).to have_http_status(:not_found)
    end

    it 'refuses to start a PDF export of a report run by another user' do
      expect do
        post document_exports_path, params: {
          type: 'SystemPathways::DocumentExports::ReportExport',
          query_string: "id=#{others_report.id}",
        }
      end.not_to change(GrdaWarehouse::DocumentExport, :count)

      expect(response).to have_http_status(:redirect)
    end
  end
end
