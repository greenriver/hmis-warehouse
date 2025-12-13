###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudSpmReport::Cells::SearchQueriesController, type: :request do
  describe 'POST #create' do
    let(:user) { create(:user) }
    let(:report) { create(:hud_reports_report_instance, user: user, options: { 'report_version' => 'fy2026' }, report_name: 'System Performance Measures - FY 2026') }
    let(:search_term) { "search_#{SecureRandom.hex(8)}" }

    before do
      user.legacy_roles << create(:role, can_view_own_hud_reports: true)
      sign_in(user)
    end

    context 'with valid parameters' do
      let(:valid_params) do
        {
          spm_id: report.id,
          measure_id: 'Q1',
          cell_id: 'B2',
          table: 'Table 1',
          q: search_term,
        }
      end

      it 'creates a ClientSearchQuery' do
        expect do
          post hud_reports_spm_measure_cell_search_queries_path(
            spm_id: report.id,
            measure_id: 'Q1',
            cell_id: 'B2',
            table: 'Table 1',
            q: search_term,
          )
        end.to change(GrdaWarehouse::ClientSearchQuery, :count).by(1)
      end

      it 'stores search term in the query' do
        post hud_reports_spm_measure_cell_search_queries_path(
          spm_id: report.id,
          measure_id: 'Q1',
          cell_id: 'B2',
          table: 'Table 1',
          q: search_term,
        )

        query = GrdaWarehouse::ClientSearchQuery.last
        expect(query.query_params[:q]).to eq(search_term)
      end

      it 'associates the query with the current user' do
        post hud_reports_spm_measure_cell_search_queries_path(
          spm_id: report.id,
          measure_id: 'Q1',
          cell_id: 'B2',
          table: 'Table 1',
          q: search_term,
        )

        query = GrdaWarehouse::ClientSearchQuery.last
        expect(query.created_by_id).to eq(user.id)
      end
    end

    context 'with unauthorized user' do
      let(:other_user) { create(:user) }

      it 'denies access to another user\'s report' do
        sign_in(other_user)

        post hud_reports_spm_measure_cell_search_queries_path(
          spm_id: report.id,
          measure_id: 'Q1',
          cell_id: 'B2',
          table: 'Table 1',
        ), params: { q: search_term }

        expect(response).to redirect_to(root_url)
        expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
      end
    end
  end
end
