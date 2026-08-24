###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessLogs::WarehouseReports::ReportsController, type: :request do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true) }
  let(:collection) { create(:collection) }
  let!(:report_definition) { create(:access_logs_report) }
  let(:viewable_reports) { [report_definition.id] }

  before do
    collection.set_viewables(reports: viewable_reports, projects: [])
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  describe 'GET #report_usage' do
    it 'renders the tab with a link to the background-render endpoint' do
      get report_usage_access_logs_warehouse_reports_reports_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Report Usage')
      expect(response.body).to include(render_report_usage_access_logs_warehouse_reports_reports_path)
    end

    context 'when the report is not viewable by the user' do
      let(:viewable_reports) { [] }

      it 'refuses to render the page' do
        get report_usage_access_logs_warehouse_reports_reports_path

        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'POST #render_report_usage' do
    it 'enqueues the background render job with the current filters and user' do
      expect do
        post render_report_usage_access_logs_warehouse_reports_reports_path, params: { render_id: 'test-render-id' }
      end.to have_enqueued_job(BackgroundRender::AccessLogsReportUsageJob).
        with('test-render-id', filters: kind_of(String), user_id: user.id)

      expect(response).to have_http_status(:ok)
    end

    context 'when the report is not viewable by the user' do
      let(:viewable_reports) { [] }

      it 'refuses to enqueue the job' do
        expect do
          post render_report_usage_access_logs_warehouse_reports_reports_path, params: { render_id: 'test-render-id' }
        end.not_to have_enqueued_job(BackgroundRender::AccessLogsReportUsageJob)

        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
