###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudDataQualityReport::LegacyResultsController, type: :request do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:collection) { create(:collection) }

  let!(:report) { Report.create!(name: 'Legacy DQ', type: 'Reports::DataQuality::Fy2017::Q1') }
  # ReportResult has no `name` column; `results` is the json payload the CSV is built from.
  let(:results) { { 'q1' => { 'title' => 'Clients', 'value' => 7 } } }
  let(:another_user) { create(:user) }
  let!(:another_users_result) do
    create(:report_result, report: report, user: another_user, percent_complete: 100, results: results)
  end

  def sign_in_with(role)
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  def download(report_result)
    get hud_reports_legacy_dq_legacy_result_path(report, report_result, format: :csv)
  end

  describe 'GET /hud_reports/legacy_dqs/:legacy_dq_id/legacy_results/:id.csv' do
    it 'denies a signed-in user with no HUD report permission' do
      sign_in_with(create(:role, can_view_clients: true))

      download(another_users_result)

      aggregate_failures do
        expect(response).to have_http_status(:redirect)
        expect(response.body).not_to include('Clients')
      end
    end

    it 'allows a user who can view all HUD reports' do
      sign_in_with(create(:role, can_view_all_hud_reports: true))

      download(another_users_result)

      aggregate_failures do
        expect(response).to have_http_status(:success)
        expect(assigns(:result)).to eq(another_users_result)
      end
    end

    context 'when the user can only view their own HUD reports' do
      before { sign_in_with(create(:role, can_view_own_hud_reports: true)) }

      it "does not serve another user's result" do
        # ReportResult.viewable_by is what draws the own/all distinction; without it,
        # holding either HUD report permission exposed every user's saved results.
        download(another_users_result)

        expect(response).to have_http_status(:not_found)
      end

      it 'still serves their own result' do
        own_result = create(:report_result, report: report, user: user, percent_complete: 100, results: results)

        download(own_result)

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(assigns(:result)).to eq(own_result)
        end
      end
    end

    it 'does not serve a result belonging to a different report' do
      # The id pair comes straight from the url; a result from another report must not
      # resolve just because both ids exist.
      sign_in_with(create(:role, can_view_all_hud_reports: true))
      other_report = Report.create!(name: 'Other Legacy DQ', type: 'Reports::DataQuality::Fy2017::Q2')
      other_reports_result = create(
        :report_result,
        report: other_report,
        user: user,
        percent_complete: 100,
        results: results,
      )

      download(other_reports_result)

      expect(response).to have_http_status(:not_found)
    end
  end
end
