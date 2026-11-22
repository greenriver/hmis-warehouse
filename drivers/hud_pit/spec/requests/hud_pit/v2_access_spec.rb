###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PIT v2 access', type: :request do
  it_behaves_like 'HUD report access' do
    let(:definition_url) { 'hud_reports/pits' }
    let(:report_name) { HudPit::Generators::Pit::Fy2025::Generator.title }
    let(:index_path) { hud_reports_pits_path }
    let(:new_path) { new_hud_reports_pit_path }
    let(:history_path) { history_hud_reports_pits_path }
    let(:report_path_for) { ->(run) { hud_reports_pit_path(run) } }
    let(:run_attributes) { { options: run_options.merge('report_version' => 'fy2025') } }

    let(:question) { 'Additional Homeless Populations' }
    let(:report) { own_run }
    let!(:report_cells) do
      ['B2', 'B4'].map { |cell_name| report.report_cells.create!(question: question, cell_name: cell_name) }
    end

    it 'opens a non-HIV cell and redirects the HIV/AIDS row for a user without HIV status' do
      granted
      base = { pit_id: report.id, question_id: question, table: question }

      get hud_reports_pit_question_cell_path(base.merge(id: 'B2'))
      expect(response).to have_http_status(:ok)

      get hud_reports_pit_question_cell_path(base.merge(id: 'B4'))
      expect(response).to redirect_to(result_hud_reports_pit_question_path(pit_id: report.id, id: question))
      expect(flash[:alert]).to eq('You do not have permission to view HIV/AIDS drilldown data.')
    end
  end
end
