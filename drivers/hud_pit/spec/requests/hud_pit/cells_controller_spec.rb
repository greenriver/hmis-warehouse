###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HudPit::CellsController#show', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:report) do
    create(
      :hud_reports_report_instance,
      user: user,
      report_name: 'Point in Time Count - FY 2025',
      options: { 'report_version' => 'fy2025' },
    )
  end
  let!(:cell) { report.report_cells.create!(question: 'Additional Homeless Populations', cell_name: 'B2') }
  let(:cell_params) { { pit_id: report.id, question_id: 'Additional Homeless Populations', id: 'B2', table: 'Additional Homeless Populations' } }

  before do
    grant_hud_report(user, 'hud_reports/pits', role: create(:role, can_view_assigned_reports: true, can_view_hiv_status: true))
    sign_in user
  end

  def build_preload_client(index)
    source = create(:grda_warehouse_hud_client, FirstName: "Preload#{index}", LastName: 'Coverage')
    destination = create(:grda_warehouse_hud_client, FirstName: "Preload#{index}", LastName: 'Coverage')
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination.id, source_id: source.id, data_source_id: source.data_source_id, id_in_source: source.id.to_s)
    pit_client = HudPit::Fy2022::PitClient.create!(
      report_instance_id: report.id,
      client_id: source.id,
      destination_client_id: destination.id,
      data_source_id: source.data_source_id,
      first_name: source.FirstName,
      last_name: source.LastName,
    )
    HudReports::UniverseMember.create!(report_cell: cell, universe_membership: pit_client, client_id: destination.id)
    destination
  end

  it 'lists every client in the cell when more clients than the preload miss threshold are in it' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }

    get hud_reports_pit_question_cell_path(cell_params)

    expect(response).to have_http_status(:ok)
    extra.each { |client| expect(response.body).to include(client.FirstName) }
  end
end
