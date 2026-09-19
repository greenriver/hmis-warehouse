###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Pre-framework HUD report pages (the legacy Report/ReportResult catalog, results
# summaries, and the old HIC export) take their access from the current report
# definition of the same family.
RSpec.describe 'Legacy HUD report pages', type: :request do
  let(:user) { create(:acl_user) }
  let(:other_user) { create(:user) }
  let!(:dq_report) { Report.create!(name: 'Legacy DQ', type: 'Reports::DataQuality::Fy2017::Q1', enabled: true) }
  let!(:spm_report) { Report.create!(name: 'Legacy SPM', type: 'Reports::SystemPerformance::Fy2019::MeasureOne', enabled: true) }
  let!(:ahar_report) { Report.create!(name: 'AHAR', type: 'Reports::Ahar::Fy2017::Base', enabled: true) }
  let(:all_hud_role) { create(:role, can_view_assigned_reports: true, can_view_all_hud_reports: true) }

  before { sign_in(user) }

  def grant_every_hud_report(role: nil)
    GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
    GrdaWarehouse::WarehouseReports::ReportDefinition.hud.pluck(:url).each { |url| grant_hud_report(user, url, role: role) }
  end

  describe 'GET /reports/:report_id/results' do
    it 'allows the family whose current definition is granted' do
      grant_hud_report(user, 'hud_reports/dqs')

      get report_report_results_path(dq_report)

      expect(response).to have_http_status(:ok)
    end

    it 'denies a family whose current definition is not granted' do
      grant_hud_report(user, 'hud_reports/dqs')

      get report_report_results_path(spm_report)

      expect(response).to have_http_status(:redirect)
    end

    it 'denies AHAR even with every HUD definition granted' do
      grant_every_hud_report

      get report_report_results_path(ahar_report)

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "another user's result without can_view_all_hud_reports" do
    let(:results) { { 'q1' => { 'title' => 'Clients', 'value' => 7, 'support' => {} } } }
    let!(:other_result) { create(:report_result, report: dq_report, user: other_user, percent_complete: 100, results: results, support: { 'k' => {} }) }

    before { grant_hud_report(user, 'hud_reports/dqs') }

    it 'is not served as support' do
      get report_report_result_support_index_path(dq_report, other_result, key: 'k')

      expect(response).to have_http_status(:not_found)
    end

    it 'is not served as CSV' do
      get report_report_result_path(dq_report, other_result, format: :csv)

      expect(response).to have_http_status(:not_found)
    end

    it 'is not served as a support download' do
      get download_support_report_report_result_path(dq_report, other_result, format: :zip)

      expect(response).to have_http_status(:not_found)
    end

    it 'is not destroyed' do
      delete report_report_result_path(dq_report, other_result)

      expect(response).to have_http_status(:not_found)
      expect(ReportResult.exists?(other_result.id)).to be true
    end

    it 'is served on the same path when it is their own' do
      own_result = create(:report_result, report: dq_report, user: user, percent_complete: 100, results: results)

      get report_report_result_path(dq_report, own_result, format: :csv)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('7')
    end
  end

  describe 'GET /report_results_summary/:id' do
    let!(:summary) { ReportResultsSummary.create!(type: 'ReportResultsSummaries::SystemPerformance::Base', name: 'SPM FY2019') }

    before { spm_report.update!(report_results_summary: summary) }

    it 'allows a user granted the current SPM definition' do
      grant_hud_report(user, 'hud_reports/spms', role: all_hud_role)

      get report_results_summary_path(summary)

      expect(response).to have_http_status(:ok)
    end

    it 'denies a user granted only another family' do
      grant_hud_report(user, 'hud_reports/dqs', role: all_hud_role)

      get report_results_summary_path(summary)

      expect(response).to have_http_status(:redirect)
    end

    context 'without can_view_all_hud_reports' do
      let!(:other_run) { create(:report_result, report: spm_report, user: other_user, percent_complete: 100, results: {}, updated_at: 1.day.ago) }

      before { grant_hud_report(user, 'hud_reports/spms') }

      it "is not found when only other users' runs exist" do
        get report_results_summary_path(summary)

        expect(response).to have_http_status(:not_found)
      end

      it 'lists their own run, not the newer run of another user' do
        own_run = create(:report_result, report: spm_report, user: user, percent_complete: 100, results: {}, updated_at: 2.days.ago)

        get report_results_summary_path(summary)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("completed on #{own_run.reload.updated_at}")
        expect(response.body).not_to include("completed on #{other_run.reload.updated_at}")
      end
    end
  end

  describe 'pages gated by a sibling definition' do
    let(:pages) do
      {
        'hud_reports/pits' => [hud_reports_historic_pits_path],
        'hud_reports/lsas' => [hud_reports_historic_lsas_path],
        'hud_reports/dqs' => [hud_reports_past_dqs_path, hud_reports_legacy_dqs_path, hud_reports_legacy_dq_path(dq_report)],
        'hud_reports/spms' => [hud_reports_legacy_spms_path],
      }
    end

    it 'open when that definition is granted' do
      grant_every_hud_report

      pages.each_value do |paths|
        paths.each do |path|
          get path
          expect(response).to have_http_status(:ok), "expected #{path} to render"
        end
      end
    end

    it 'redirect when only a different HUD definition is granted' do
      grant_hud_report(user, 'hud_reports/hopwa_capers')

      pages.each_value do |paths|
        paths.each do |path|
          get path
          expect(response).to have_http_status(:redirect), "expected #{path} to redirect"
        end
      end
    end
  end

  describe 'GET /reports/hic/export' do
    it 'allows a user granted the current HIC definition' do
      grant_hud_report(user, 'hud_reports/hics')

      get reports_hic_export_path

      expect(response).to have_http_status(:ok)
    end

    it 'denies a user granted only another family' do
      grant_hud_report(user, 'hud_reports/dqs')

      get reports_hic_export_path

      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'legacy index pages with no results summary' do
    it 'renders the legacy SPM list' do
      grant_hud_report(user, 'hud_reports/spms')

      get hud_reports_legacy_spms_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Legacy SPM')
    end

    it 'renders the legacy DQ list' do
      grant_hud_report(user, 'hud_reports/dqs')

      get hud_reports_legacy_dqs_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Legacy DQ')
    end

    it 'renders a legacy DQ report page with a result' do
      grant_hud_report(user, 'hud_reports/dqs')
      create(:report_result, report: dq_report, user: user, percent_complete: 100, results: { 'q1' => { 'title' => 'Clients', 'value' => 7 } })

      get hud_reports_legacy_dq_path(dq_report)

      expect(response).to have_http_status(:ok)
    end
  end
end
