###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudSpmReport::LegacyResultsController, type: :request do
  let(:user) { create(:acl_user) }
  let!(:report) { Report.create!(name: 'Legacy SPM', type: 'Reports::SystemPerformance::Fy2019::MeasureOne') }
  let(:results) { { 'onea_c2' => { 'title' => 'Persons', 'value' => 7 } } }
  let(:another_user) { create(:user) }
  let!(:another_users_result) do
    create(:report_result, report: report, user: another_user, percent_complete: 100, results: results)
  end

  def sign_in_with(role)
    grant_hud_report(user, 'hud_reports/spms', role: role)
    sign_in(user)
  end

  def download(report_result)
    get hud_reports_legacy_spm_legacy_result_path(report, report_result, format: :csv)
  end

  describe 'GET /hud_reports/legacy_spms/:legacy_spm_id/legacy_results/:id.csv' do
    it "does not serve another user's result without can_view_all_hud_reports" do
      sign_in_with(create(:role, can_view_assigned_reports: true))

      download(another_users_result)

      expect(response).to have_http_status(:not_found)
    end

    it 'serves their own result' do
      sign_in_with(create(:role, can_view_assigned_reports: true))
      own_result = create(:report_result, report: report, user: user, percent_complete: 100, results: results)

      download(own_result)

      expect(response).to have_http_status(:success)
      expect(assigns(:result)).to eq(own_result)
    end

    it "serves another user's result with can_view_all_hud_reports" do
      sign_in_with(create(:role, can_view_assigned_reports: true, can_view_all_hud_reports: true))

      download(another_users_result)

      expect(response).to have_http_status(:success)
      expect(assigns(:result)).to eq(another_users_result)
    end

    it 'does not serve a result belonging to a different legacy report' do
      sign_in_with(create(:role, can_view_assigned_reports: true, can_view_all_hud_reports: true))
      other_report = Report.create!(name: 'Other Legacy SPM', type: 'Reports::SystemPerformance::Fy2019::MeasureTwo')
      other_reports_result = create(:report_result, report: other_report, user: user, percent_complete: 100, results: results)

      download(other_reports_result)

      expect(response).to have_http_status(:not_found)
    end
  end
end
