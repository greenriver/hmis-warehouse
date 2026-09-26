###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::DisabilitiesController#show', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/disabilities', name: 'Enrolled clients with selected disabilities') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restrictedfirst', last_name: 'Restrictedlast') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restrictedfirst', LastName: 'Restrictedlast') }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Openfirst', last_name: 'Openlast') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Openfirst', LastName: 'Openlast') }

  def client_row(client)
    {
      'id' => client.id,
      'FirstName' => client.FirstName,
      'LastName' => client.LastName,
      'VeteranStatus' => 0,
      'enrollment' => { 'age' => 40, 'unaccompanied_youth' => false, 'parenting_youth' => false, 'head_of_household' => true },
      'disabilities' => ['Physical: Yes'],
    }
  end

  let!(:disability_report) do
    create(:enrolled_disabled_report, data: [client_row(restricted_destination_client), client_row(open_destination_client)])
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  it 'redacts only the restricted client name in the html view' do
    get warehouse_reports_disability_path(disability_report)

    expect(response.body).not_to include('Restrictedfirst')
    expect(response.body).not_to include('Restrictedlast')
    expect(response.body).to include('Name Redacted')
    expect(response.body).to include('Openfirst')
    expect(response.body).to include('Openlast')
  end

  def rendered_workbook
    excel_file = Tempfile.new(['disabilities', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'redacts only the restricted client name in the Excel export' do
    get warehouse_reports_disability_path(disability_report, format: :xlsx)

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    rows = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }

    restricted_row = rows.find { |r| r[0] == restricted_destination_client.id }
    expect(restricted_row[1]).to eq('Name Redacted')
    expect(restricted_row[2]).to eq('Name Redacted')

    open_row = rows.find { |r| r[0] == open_destination_client.id }
    expect(open_row[1]).to eq('Openfirst')
    expect(open_row[2]).to eq('Openlast')
  end

  def build_preload_client(index)
    source = create(:hmis_hud_client, data_source: hmis_ds, first_name: "Preload#{index}", last_name: 'Coverage')
    destination = create(:grda_warehouse_hud_client, FirstName: "Preload#{index}", LastName: 'Coverage')
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination.id, source_id: source.id, data_source_id: hmis_ds.id, id_in_source: source.id.to_s)

    destination
  end

  def add_preload_rows(clients)
    disability_report.update!(data: disability_report.data + clients.map { |c| client_row(c) })
  end

  it 'lists every client when more clients than the preload miss threshold are in the report' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }
    add_preload_rows(extra)

    get warehouse_reports_disability_path(disability_report)

    expect(response).to have_http_status(:ok)
    extra.each { |client| expect(response.body).to include(client.FirstName) }
  end

  it 'exports every client when more clients than the preload miss threshold are in the report' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }
    add_preload_rows(extra)

    get warehouse_reports_disability_path(disability_report, format: :xlsx)

    expect(response).to have_http_status(:ok)
    expect(xlsx_cell_values(response)).to include(*extra.map(&:FirstName))
  end
end
