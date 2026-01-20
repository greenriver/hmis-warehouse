###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudSpmReport::CellsController, type: :request do
  let(:user) { create(:user) }
  let(:report) { create(:hud_reports_report_instance, user: user, options: { 'report_version' => 'fy2026' }, report_name: 'System Performance Measures - FY 2026') }

  before do
    user.legacy_roles << create(:role, can_view_own_hud_reports: true)
    sign_in(user)
  end

  describe 'GET #show' do
    it 'renders the show template with pagination' do
      get hud_reports_spm_measure_cell_path(spm_id: report.id, measure_id: 'Measure 1', id: 'B2', table: '1a')

      expect(response).to be_successful
      expect(assigns(:pagy)).to be_present
      expect(assigns(:clients)).to be_a(ActiveRecord::Relation)
    end

    context 'with unauthorized user' do
      let(:other_user) { create(:user) }

      it 'denies access to another user\'s report' do
        sign_in(other_user)
        get hud_reports_spm_measure_cell_path(spm_id: report.id, measure_id: 'Measure 1', id: 'B2', table: '1a')
        expect(response).to redirect_to(root_url)
      end

      it 'allows access if user has can_view_all_hud_reports permission' do
        other_user.legacy_roles << create(:role, can_view_all_hud_reports: true)
        sign_in(other_user)
        get hud_reports_spm_measure_cell_path(spm_id: report.id, measure_id: 'Measure 1', id: 'B2', table: '1a')
        expect(response).to be_successful
      end
    end

    context 'XLSX format' do
      it 'queues an export and redirects' do
        get hud_reports_spm_measure_cell_path(spm_id: report.id, measure_id: 'Measure 1', id: 'B2', table: '1a', format: :xlsx)

        expect(response).to redirect_to(hud_reports_spm_path(report))
        expect(flash[:notice]).to match(/export is being generated/)
        expect(GrdaWarehouse::DocumentExport.last.type).to eq('HudSpmReport::DocumentExports::CellDetailExport')
      end
    end
  end

  describe 'GET #search' do
    let(:search_term) { 'John' }
    let(:query) { create(:grda_warehouse_client_search_query, created_by: user, params: { q: search_term }) }

    it 'renders the show template with filtered results' do
      get search_hud_reports_spm_measure_cell_path(spm_id: report.id, measure_id: 'Measure 1', id: 'B2', query_id: query.id, table: '1a')

      expect(response).to be_successful
      expect(assigns(:drilldown).search_term).to eq(search_term)
    end
  end
end
