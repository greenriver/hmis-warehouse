###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Past HUD Data Quality report pages', type: :request do
  let(:user) { create(:acl_user) }
  let(:question_path) { hud_reports_past_dq_question_path(past_dq_id: 0, id: 'Question 1') }

  before { Rails.cache.clear }

  it 'renders a question page for a user granted the DQ definition' do
    grant_hud_report(user, 'hud_reports/dqs')
    sign_in(user)

    get question_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Question 1')
  end

  it 'redirects a user granted only the APR definition' do
    grant_hud_report(user, 'hud_reports/aprs')
    sign_in(user)

    get question_path

    expect(response).to have_http_status(:redirect)
    expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
  end

  describe 'retired DQ years' do
    let(:seeded_name) { 'Zanzibar' }
    let(:run) do
      create(
        :hud_reports_report_instance,
        user_id: user.id,
        report_name: HudDataQualityReport::Generators::Fy2022::Generator.title,
        state: 'Completed',
      )
    end

    def cell_path(**args)
      hud_reports_past_dq_question_cell_path(past_dq_id: run.id, question_id: 'Question 6', id: 'B2', table: 'Q6', **args)
    end

    before do
      grant_hud_report(user, 'hud_reports/dqs')
      sign_in(user)
    end

    context 'with a member in the requested cell' do
      before do
        cell = HudReports::ReportCell.create!(report_instance: run, question: 'Q6', cell_name: 'B2')
        dq_client = HudDataQualityReport::Fy2020::DqClient.create!(report_instance_id: run.id, first_name: seeded_name)
        HudReports::UniverseMember.create!(
          report_cell: cell,
          universe_membership: dq_client,
          client: create(:grda_warehouse_hud_client),
        )
      end

      it 'redirects xlsx cell requests without client rows' do
        get cell_path(format: :xlsx)

        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
        expect(response.media_type).not_to include('spreadsheetml')
        expect(response.body).not_to include(seeded_name)
      end

      it 'redirects html cell requests without client rows' do
        get cell_path

        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
        expect(response.body).not_to include(seeded_name)
      end
    end

    describe 'creating a report' do
      before do
        coc = GrdaWarehouse::Lookups::CocCode.create!(coc_code: 'XX-500', official_name: 'Test CoC', active: true)
        coc_collection = create(:collection, collection_type: 'Projects')
        coc_collection.set_viewables(coc_codes: [coc.id])
        setup_access_control(user, create(:role, can_view_assigned_reports: true), coc_collection)
      end

      let(:filter_params) { { report_version: 'fy2022', start: '2021-10-01', end: '2022-09-30', coc_codes: ['XX-500'] } }

      it 'does not create or queue a run from the questions endpoint' do
        expect do
          post hud_reports_past_dq_questions_path(past_dq_id: 0), params: { question: 'Question 1', filter: filter_params }
        end.not_to change(HudReports::ReportInstance, :count)

        expect(Reporting::Hud::RunReportJob).not_to have_been_enqueued

        expect(response).to redirect_to(hud_reports_past_dqs_path)
        expect(flash[:alert]).to eq('This report version can no longer be run.')
      end

      it 'does not create or queue a run from the report endpoint' do
        expect do
          post hud_reports_past_dqs_path, params: { filter: filter_params }
        end.not_to change(HudReports::ReportInstance, :count)

        expect(Reporting::Hud::RunReportJob).not_to have_been_enqueued

        expect(response).to redirect_to(hud_reports_past_dqs_path)
        expect(flash[:alert]).to eq('This report version can no longer be run.')
      end

      it 'refuses an unknown report version' do
        expect do
          post hud_reports_past_dqs_path, params: { filter: { report_version: 'fy1999', coc_codes: ['XX-500'] } }
        end.not_to change(HudReports::ReportInstance, :count)

        expect(response).to redirect_to(hud_reports_past_dqs_path)
        expect(flash[:alert]).to eq('This report version can no longer be run.')
      end
    end
  end
end
