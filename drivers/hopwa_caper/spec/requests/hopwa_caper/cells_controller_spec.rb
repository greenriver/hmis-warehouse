###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../models/generators/fy2026/hopwa_caper_shared_context'

RSpec.describe HopwaCaper::CellsController, type: :request do
  include_context 'HOPWA CAPER shared context'

  let(:tbra_funder) { hud_code(:funding_sources, 'HUD: HOPWA - Permanent Housing (facility based or TBRA)') }
  let(:project) { create_hopwa_project(funder: tbra_funder) }
  let(:report) { create_report([project]) }
  let(:hiv_role) { create(:role, can_view_hiv_status: true, can_view_client_name: true) }
  let(:denial) { 'You do not have permission to view HIV/AIDS drilldown data.' }
  let(:cell) do
    report.report_cells.detect { |c| c.universe_members.exists? }
  end
  let(:question) do
    generator.questions.keys.find { |q| report.existing_universe(q)&.metadata&.fetch('tables', [])&.include?(cell.question) }
  end
  let(:cell_path_args) { { hopwa_caper_id: report.id, question_id: question, id: cell.cell_name, table: cell.question } }
  let(:result_path) { result_hud_reports_hopwa_caper_question_path(hopwa_caper_id: report.id, id: question) }

  before do
    create_hiv_positive_enrollment(
      client: create_client_with_warehouse_link(first_name: 'Ann', last_name: 'Able'),
      project: project,
      entry_date: report_start_date,
      household_id: Hmis::Hud::Base.generate_uuid,
      relationship_to_ho_h: 1,
    )
    run_report(report)
    grant_hud_report(user, 'hud_reports/hopwa_capers')
    sign_in(user)
  end

  context 'when the user can view HIV status on the project' do
    before { grant_project_access(user, hiv_role, [project], mode: :acl) }

    it 'renders the cell drilldown' do
      get hud_reports_hopwa_caper_question_cell_path(cell_path_args)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Ann')
    end

    it 'links populated cells on the result page' do
      get result_path

      expect(response.body).to include(hud_reports_hopwa_caper_question_cell_path(cell_path_args))
    end
  end

  context 'when the user cannot view HIV status on the project' do
    it 'redirects the HTML drilldown to the result page with the denial alert' do
      get hud_reports_hopwa_caper_question_cell_path(cell_path_args)

      expect(response).to redirect_to(result_path)
      expect(flash[:alert]).to eq(denial)
    end

    it 'redirects the xlsx drilldown without sending a file' do
      get hud_reports_hopwa_caper_question_cell_path(cell_path_args.merge(format: :xlsx))

      expect(response).to redirect_to(result_path)
      expect(response.headers['Content-Disposition']).to be_nil
      expect(flash[:alert]).to eq(denial)
    end

    it 'omits drilldown links from the result page' do
      get result_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(hud_reports_hopwa_caper_question_cell_path(cell_path_args))
      expect(response.body).not_to include("/questions/#{question}/cells/")
    end
  end
end
