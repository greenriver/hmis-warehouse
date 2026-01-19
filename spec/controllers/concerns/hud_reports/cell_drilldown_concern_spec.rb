###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::CellDrilldownConcern, type: :controller do
  # Dummy controller to test the concern
  controller(ApplicationController) do
    include HudReports::CellDrilldownConcern

    def report_param_name = :report_id
    def measure_id = 'Q1'
    def export_class_name = 'HudApr::DocumentExports::CellDetailExport'
    def export_job_class = HudApr::CellDetailExportJob
    def export_query_params = { foo: 'bar' }
    def fallback_path = '/fallback'
    def path_for_cell_without_search = '/cell'

    def set_report
      @report = HudReports::ReportInstance.new(id: params[:report_id], user_id: current_user.id)
    end

    def generator
      HudReports::GeneratorBase
    end

    def render_html_response(scope)
      # Override to avoid template lookup in tests
      @pagy, @clients = pagy(scope)
      head :ok
    end

    def render_xlsx_response
      # Override to avoid template lookup or complex export logic if needed
      # but concern already handles it. We just need to ensure paths are mocked.
      super
    end
  end

  before do
    routes.draw do
      get 'anonymous/show' => 'anonymous#show'
      get 'anonymous/search' => 'anonymous#search'
    end
  end

  let(:user) { create(:user) }
  let(:drilldown_context) do
    HudReports::DrilldownContext.new(
      report: HudReports::ReportInstance.new(id: 1, user_id: user.id),
      measure: 'Q1',
      cell: 'A1',
      table: 'T1',
      generator: HudReports::GeneratorBase,
      name: 'Test Name',
    ).tap do |ctx|
      allow(ctx).to receive(:base_scope).and_return(HudApr::Fy2020::AprClient.all)
    end
  end

  before do
    sign_in user
    allow(HudReports::GeneratorBase).to receive(:drilldown_context).and_return(drilldown_context)
    # Stub pagy to avoid needing real database records for simple tests
    allow(controller).to receive(:pagy).and_return([double('pagy', offset: 0), HudApr::Fy2020::AprClient.none])
  end

  describe 'GET #show' do
    it 'sets drilldown context and renders show' do
      get :show, params: { report_id: 1, id: 'A1', table: 'T1' }
      expect(assigns(:drilldown)).to eq(drilldown_context)
      expect(response).to have_http_status(:success)
    end

    it 'handles missing parameters' do
      # ActionController::ParameterMissing is rescued and redirects to root_path
      get :show, params: { id: 'A1' } # missing report_id and table
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('The requested information could not be loaded')
    end
  end

  describe 'GET #search' do
    let(:search_query) { create(:grda_warehouse_client_search_query, created_by: user, params: { q: 'John' }) }

    it 'applies search query and renders show' do
      expect(drilldown_context).to receive(:apply_search_query!).with(search_query)

      get :search, params: { report_id: 1, id: 'A1', table: 'T1', query_id: search_query.id }
      expect(response).to have_http_status(:success)
    end

    it 'handles missing search query' do
      get :search, params: { report_id: 1, id: 'A1', table: 'T1', query_id: 0 }
      expect(response).to redirect_to('/cell')
      expect(flash[:error]).to eq('Search query not found')
    end
  end

  describe 'GET #show (XLSX)' do
    it 'creates a document export and redirects' do
      expect do
        get :show, params: { report_id: 1, id: 'A1', table: 'T1' }, format: :xlsx
      end.to change(GrdaWarehouse::DocumentExport, :count).by(1)

      export = GrdaWarehouse::DocumentExport.last
      expect(export.type).to eq('HudApr::DocumentExports::CellDetailExport')
      expect(export.query_string).to eq('foo=bar')

      expect(response).to redirect_to('/fallback')
      expect(flash[:notice]).to match(/export is being generated/)
    end
  end
end
