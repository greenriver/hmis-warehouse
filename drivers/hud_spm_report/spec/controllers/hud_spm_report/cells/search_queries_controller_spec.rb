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
    let(:report) { create(:hud_reports_report_instance, user: user, options: { 'report_version' => 'fy2026' }) }

    before do
      login_user(user)
    end

    context 'with valid parameters' do
      let(:valid_params) do
        {
          spm_id: report.id,
          measure_id: 'Q1',
          cell_id: 'B2',
          table: 'Table 1',
          q: 'john',
        }
      end

      it 'creates a ClientSearchQuery' do
        expect do
          post hud_reports_spm_measure_cell_search_queries_path(
            spm_id: report.id,
            measure_id: 'Q1',
            cell_id: 'B2',
            table: 'Table 1',
          ), params: { q: 'john' }
        end.to change(GrdaWarehouse::ClientSearchQuery, :count).by(1)
      end

      it 'redirects to search action' do
        post hud_reports_spm_measure_cell_search_queries_path(
          spm_id: report.id,
          measure_id: 'Q1',
          cell_id: 'B2',
          table: 'Table 1',
        ), params: { q: 'john' }

        query = GrdaWarehouse::ClientSearchQuery.last
        expect(response).to redirect_to(
          search_hud_reports_spm_measure_cell_path(
            spm_id: report.id,
            measure_id: 'Q1',
            id: 'B2',
            query_id: query.id,
            table: 'Table 1',
          ),
        )
      end

      it 'stores search term in the query' do
        post hud_reports_spm_measure_cell_search_queries_path(
          spm_id: report.id,
          measure_id: 'Q1',
          cell_id: 'B2',
          table: 'Table 1',
        ), params: { q: 'john' }

        query = GrdaWarehouse::ClientSearchQuery.last
        expect(query.query_params[:q]).to eq('john')
      end

      it 'associates the query with the current user' do
        post hud_reports_spm_measure_cell_search_queries_path(
          spm_id: report.id,
          measure_id: 'Q1',
          cell_id: 'B2',
          table: 'Table 1',
        ), params: { q: 'john' }

        query = GrdaWarehouse::ClientSearchQuery.last
        expect(query.user_id).to eq(user.id)
      end
    end

    context 'with invalid search query' do
      it 'redirects back to cell view with error flash' do
        allow_any_instance_of(GrdaWarehouse::ClientSearchQuery).to receive(:valid?).and_return(false)

        post hud_reports_spm_measure_cell_search_queries_path(
          spm_id: report.id,
          measure_id: 'Q1',
          cell_id: 'B2',
          table: 'Table 1',
        ), params: { q: 'john' }

        expect(response).to redirect_to(
          hud_reports_spm_measure_cell_path(
            spm_id: report.id,
            measure_id: 'Q1',
            id: 'B2',
            table: 'Table 1',
          ),
        )
        expect(flash[:error]).to eq('Search query not valid')
      end
    end

    context 'with missing parameters' do
      it 'raises error when measure_id is missing' do
        expect do
          post hud_reports_spm_measure_cell_search_queries_path(
            spm_id: report.id,
            cell_id: 'B2',
            table: 'Table 1',
          ), params: { q: 'john' }
        end.to raise_error(ActionController::ParameterMissing)
      end

      it 'raises error when cell_id is missing' do
        expect do
          post hud_reports_spm_measure_cell_search_queries_path(
            spm_id: report.id,
            measure_id: 'Q1',
            table: 'Table 1',
          ), params: { q: 'john' }
        end.to raise_error(ActionController::ParameterMissing)
      end

      it 'raises error when table is missing' do
        expect do
          post hud_reports_spm_measure_cell_search_queries_path(
            spm_id: report.id,
            measure_id: 'Q1',
            cell_id: 'B2',
          ), params: { q: 'john' }
        end.to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'with non-existent report' do
      it 'returns 404 when report does not exist' do
        expect do
          post hud_reports_spm_measure_cell_search_queries_path(
            spm_id: 99_999,
            measure_id: 'Q1',
            cell_id: 'B2',
            table: 'Table 1',
          ), params: { q: 'john' }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with unauthorized user' do
      let(:other_user) { create(:user) }

      it 'denies access to another user\'s report' do
        login_user(other_user)

        post hud_reports_spm_measure_cell_search_queries_path(
          spm_id: report.id,
          measure_id: 'Q1',
          cell_id: 'B2',
          table: 'Table 1',
        ), params: { q: 'john' }

        # The before_action :filter in BaseController should prevent access
        # Exact response depends on authentication/authorization setup
        expect(response.status).to be_in([403, 404, 401])
      end
    end
  end
end
