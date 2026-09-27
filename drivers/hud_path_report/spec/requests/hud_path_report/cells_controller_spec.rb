###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HudPathReport::CellsController#show', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:report) { HudReports::ReportInstance.create!(user_id: user.id, report_name: 'Annual PATH Report - FY 2026', options: { 'report_version' => 'fy2026' }, question_names: []) }
  let!(:cell) { report.report_cells.create!(question: 'Q8-Q16', cell_name: 'B2') }

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    grant_hud_report(user, 'hud_reports/paths')
    sign_in user
  end

  def build_preload_client(index)
    source = create(:grda_warehouse_hud_client, FirstName: "Preload#{index}", LastName: 'Coverage')
    destination = create(:grda_warehouse_hud_client, FirstName: "Preload#{index}", LastName: 'Coverage')
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination.id, source_id: source.id, data_source_id: source.data_source_id, id_in_source: source.id.to_s)
    path_client = HudPathReport::Fy2020::PathClient.create!(
      report_instance_id: report.id,
      client_id: source.id,
      destination_client_id: destination.id,
      personal_id: source.PersonalID,
      data_source_id: source.data_source_id,
      first_name: source.FirstName,
      last_name: source.LastName,
      contacts: [],
    )
    HudReports::UniverseMember.create!(report_cell: cell, universe_membership: path_client, client_id: destination.id)
    destination
  end

  it 'lists every client in the cell when more clients than the preload miss threshold are in it' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }

    get hud_reports_path_question_cell_path(path_id: report.id, question_id: 'Q8-Q16', id: 'B2', table: 'Q8-Q16')

    expect(response).to have_http_status(:ok)
    extra.each { |client| expect(response.body).to include(client.FirstName) }
  end

  it 'exports every client in the cell when more clients than the preload miss threshold are in it' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }

    get hud_reports_path_question_cell_path(path_id: report.id, question_id: 'Q8-Q16', id: 'B2', table: 'Q8-Q16', format: :xlsx)

    expect(response).to have_http_status(:ok)
    expect(xlsx_cell_values(response)).to include(*extra.map(&:FirstName))
  end
end
