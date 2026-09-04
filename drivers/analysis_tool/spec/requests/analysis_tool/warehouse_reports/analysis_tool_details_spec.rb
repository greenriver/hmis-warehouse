###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AnalysisTool::WarehouseReports::AnalysisTool#details', type: :request do
  let!(:report_role) { create(:role, can_view_assigned_reports: true, can_view_clients: true, can_view_client_name: true) }
  let!(:user) do
    user = create(:user)
    user.legacy_roles << report_role
    user
  end

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:window_data_source) { create(:visible_data_source) }
  let!(:open_source_client) { create(:hud_client, data_source: window_data_source, FirstName: 'Open', LastName: 'Doe') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Doe') }

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    allow_any_instance_of(AnalysisTool::WarehouseReports::AnalysisToolController).to receive(:report_visible?).and_return(true)
    allow_any_instance_of(AnalysisTool::Report).to receive(:support_title).and_return('Test Breakdown')
    allow_any_instance_of(AnalysisTool::Report).to receive(:support_for).and_return(
      GrdaWarehouse::Hud::Client.where(id: [restricted_destination_client.id, open_destination_client.id]),
    )
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: window_data_source.id, id_in_source: open_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in(user)
  end

  it 'redacts the restricted client and shows the unrestricted client in the HTML view' do
    get details_analysis_tool_warehouse_reports_analysis_tool_index_path(cell: [0, 0])

    expect(response).to have_http_status(:success)
    expect(response.body).not_to include('Restricted')
    expect(response.body).to include(GrdaWarehouse::PiiProvider::NAME_REDACTED)
    expect(response.body).to include('>Open<')
    expect(response.body).to include('>Doe<')
  end

  it 'redacts the restricted client and shows the unrestricted client in the Excel export when the download toggle is on' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

    get details_analysis_tool_warehouse_reports_analysis_tool_index_path(cell: [0, 0], format: :xlsx)

    expect(response).to have_http_status(:success)
    excel_file = Tempfile.new(['analysis_tool_details', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    sheet = Roo::Excelx.new(excel_file.path).sheet(0)
    rows = (sheet.first_row + 1..sheet.last_row).map { |i| sheet.row(i) }
    restricted_row = rows.find { |r| r[0] == restricted_destination_client.id }
    open_row = rows.find { |r| r[0] == open_destination_client.id }

    expect(restricted_row[1]).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
    expect(open_row[1]).to eq('Open')
  ensure
    excel_file&.unlink
  end
end
