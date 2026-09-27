###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../models/generators/fy2026/hopwa_caper_shared_context'

RSpec.describe 'HopwaCaper::CellsController#show', type: :request do
  include_context 'HOPWA CAPER shared context'

  let(:report_viewer) { create(:report_viewer, can_view_projects: true, can_view_client_name: true) }
  let(:tbra_funder) { hud_code(:funding_sources, 'HUD: HOPWA - Permanent Housing (facility based or TBRA)') }
  let(:project) { create_hopwa_project(funder: tbra_funder) }
  let(:report) { create_report([project]) }

  before do
    grant_hud_report(user, 'hud_reports/hopwa_capers')
    sign_in(user)
  end

  it 'lists every client in the cell when more clients than the preload miss threshold are in it' do
    extra = Array.new(preload_miss_client_count) do |i|
      source = create_client_with_warehouse_link(first_name: "Preload#{i}", last_name: 'Coverage')
      create_hiv_positive_enrollment(client: source, project: project, entry_date: report_start_date, household_id: "preload-#{i}")
      source
    end
    run_report(report)
    cell = report.report_cells.detect { |c| c.universe_members.count >= preload_miss_client_count }

    get hud_reports_hopwa_caper_question_cell_path(hopwa_caper_id: report.id, question_id: cell.question, id: cell.cell_name, table: cell.question)

    expect(response).to have_http_status(:ok)
    extra.each { |client| expect(response.body).to include(client.FirstName) }
  end
end
