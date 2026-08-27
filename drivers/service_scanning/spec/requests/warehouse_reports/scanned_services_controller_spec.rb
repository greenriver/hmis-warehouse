###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ServiceScanning::WarehouseReports::ScannedServicesController#detail', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:role) { create(:role, can_use_service_register: true, can_view_clients: true, can_view_all_reports: true, can_view_assigned_reports: true) }
  let!(:collection) { create(:collection) }
  let!(:report) { create(:touch_point_report, url: 'service_scanning/warehouse_reports/scanned_services', name: 'Scanned Services') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:project) { create(:hud_project) }
  let!(:service) { ServiceScanning::OtherService.create!(client_id: restricted_destination_client.id, project: project, provided_at: Time.current, user: user) }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  let(:filter_params) { { start: Date.current.to_s, end: (Date.current + 1.day).to_s, project_ids: [project.id], service_type: 'other' } }

  it 'redacts the client name for a restricted client' do
    get detail_service_scanning_warehouse_reports_scanned_services_path(filters: filter_params)

    expect(response.body).not_to include('Restricted Client')
    expect(response.body).to include('Name Redacted')
  end

  # `.xlsx` responses are a compressed OOXML zip, not plain text — `response.body.include?` would
  # pass even on unredacted data, since the raw string never appears uncompressed. Parse the actual
  # workbook instead, matching the established pattern used throughout this build.
  def rendered_workbook
    excel_file = Tempfile.new(['scanned_services', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'redacts the client name in the detail Excel export' do
    get detail_service_scanning_warehouse_reports_scanned_services_path(filters: filter_params, format: :xlsx)

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    row = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }.find { |r| r[0] == restricted_destination_client.id }
    expect(row[1]).to eq('Name Redacted')
    expect(row[2]).to eq('Name Redacted')
  end

  it 'redacts the client name in the index Excel export' do
    get service_scanning_warehouse_reports_scanned_services_path(filters: filter_params, format: :xlsx)

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    row = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }.find { |r| r[0] == restricted_destination_client.id }
    expect(row[1]).to eq('Name Redacted')
    expect(row[2]).to eq('Name Redacted')
  end
end
