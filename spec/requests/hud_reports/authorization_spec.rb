###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HUD report authorization', type: :request do
  let(:user) { create(:acl_user) }
  let(:other_user) { create(:acl_user) }
  let(:apr_title) { HudApr::Generators::Apr::Fy2026::Generator.title }
  let(:run_options) { { 'start' => '2025-10-01', 'end' => '2026-09-30', 'project_ids' => [] } }

  before { sign_in(user) }

  it 'denies a user whose role has HUD flags but no report definition granted' do
    setup_access_control(user, create(:role, can_view_all_hud_reports: true, can_view_own_hud_reports: true), create(:collection))

    get hud_reports_aprs_path

    expect(response).to have_http_status(:redirect)
  end

  it 'allows a user granted the APR definition and lists only granted HUD reports in the side nav' do
    grant_hud_report(user, 'hud_reports/aprs')

    get hud_reports_aprs_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(hud_reports_aprs_path)
    expect(response.body).not_to include(hud_reports_spms_path)
  end

  it 'does not let an APR grant open the SPM report' do
    grant_hud_report(user, 'hud_reports/aprs')

    get hud_reports_spms_path

    expect(response).to have_http_status(:redirect)
  end

  describe 'report run ownership' do
    let!(:own_run) { create(:hud_reports_report_instance, user: user, report_name: apr_title, options: run_options) }
    let!(:other_run) { create(:hud_reports_report_instance, user: other_user, report_name: apr_title, options: run_options) }

    it 'shows only own runs without can_view_all_hud_reports' do
      grant_hud_report(user, 'hud_reports/aprs')

      get history_hud_reports_aprs_path

      expect(response.body).to include(hud_reports_apr_path(own_run))
      expect(response.body).not_to include(hud_reports_apr_path(other_run))
    end

    it 'shows every run with can_view_all_hud_reports' do
      grant_hud_report(user, 'hud_reports/aprs', role: create(:role, can_view_assigned_reports: true, can_view_all_hud_reports: true))

      get history_hud_reports_aprs_path

      expect(response.body).to include(hud_reports_apr_path(own_run), hud_reports_apr_path(other_run))
    end
  end

  describe 'warehouse reports index for a legacy user with only a HUD flag' do
    let(:user) { create(:user) }
    let(:other_report) { GrdaWarehouse::WarehouseReports::ReportDefinition.find_by!(url: 'warehouse_reports/client_lookups') }

    it 'lists granted HUD reports but not other reports sitting in the same access group' do
      grant_hud_report(user, 'hud_reports/aprs', role: create(:role, can_view_own_hud_reports: true))
      user.access_group.add_viewable(other_report)

      get warehouse_reports_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Annual Performance Report')
      expect(response.body).not_to include(other_report.name)
    end
  end

  describe 'LSA-derived HIC' do
    it 'opens with the LSA definition' do
      grant_hud_report(user, 'hud_reports/lsas')

      get hud_reports_lsa_hics_path

      expect(response).to have_http_status(:ok)
    end

    it 'does not open with only the HIC definition' do
      grant_hud_report(user, 'hud_reports/hics')

      get hud_reports_lsa_hics_path

      expect(response).to have_http_status(:redirect)
    end
  end
end
