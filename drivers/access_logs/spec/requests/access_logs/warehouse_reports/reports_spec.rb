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

  describe 'GET #index' do
    it 'omits the HMIS user select when the HMIS is disabled' do
      allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(false)

      get access_logs_warehouse_reports_reports_path

      expect(response.body).not_to include('filters[hmis_user_id]')
    end

    context 'when the HMIS is enabled' do
      let!(:hmis_user) { create(:hmis_user, first_name: 'Ada', last_name: 'Lovelace') }
      let!(:non_hmis_user) { create(:user, first_name: 'Zed', last_name: 'Nohmis') }

      before { create(:hmis_access_control, with_users: [hmis_user]) }

      it 'offers only HMIS users in the HMIS user select' do
        get access_logs_warehouse_reports_reports_path

        select = Nokogiri::HTML5(response.body).at_css('select[name="filters[hmis_user_id]"]')
        expect(select.css('option').map(&:text)).to contain_exactly('All', hmis_user.name_with_email)
      end
    end
  end

  describe 'POST #create' do
    let(:hmis_user) { create(:hmis_user) }

    it 'queues the export with the chosen HMIS user' do
      expect do
        post access_logs_warehouse_reports_reports_path, params: { filters: { start: '2026-08-01', end: '2026-08-31', hmis_user_id: hmis_user.id } }
      end.to have_enqueued_job(::WarehouseReports::AccessLogsExportJob).with(hash_including(hmis_user_id: hmis_user.id.to_s))

      expect(response).to redirect_to(access_logs_warehouse_reports_reports_path)
    end
  end

  describe 'GET #user_summary' do
    it 'renders the tab with a link to its background-render endpoint' do
      get user_summary_access_logs_warehouse_reports_reports_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(render_user_summary_access_logs_warehouse_reports_reports_path)
    end

    context 'when the report is not viewable by the user' do
      let(:viewable_reports) { [] }

      it 'refuses to render the page' do
        get user_summary_access_logs_warehouse_reports_reports_path

        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'POST #render_user_summary' do
    it 'enqueues the background render job with the current filters and user' do
      expect do
        post render_user_summary_access_logs_warehouse_reports_reports_path, params: { render_id: 'test-render-id' }
      end.to have_enqueued_job(BackgroundRender::AccessLogsUserSummaryJob).
        with('test-render-id', filters: kind_of(String), user_id: user.id)

      expect(response).to have_http_status(:ok)
    end

    context 'when the report is not viewable by the user' do
      let(:viewable_reports) { [] }

      it 'refuses to enqueue the job' do
        expect do
          post render_user_summary_access_logs_warehouse_reports_reports_path, params: { render_id: 'test-render-id' }
        end.not_to have_enqueued_job(BackgroundRender::AccessLogsUserSummaryJob)

        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
