###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::ClientInProjectDuringDateRangeController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_projects: true, can_view_client_name: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/client_in_project_during_date_range', name: 'Client in Project During Date Range') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'RClient') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'RClient', DOB: '1990-01-01') }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'OClient') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'OClient', DOB: '1990-01-01') }
  let!(:project_data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: project_data_source) }
  let!(:project) { create(:hud_project, data_source: project_data_source, OrganizationID: organization.OrganizationID, ProjectType: 1, TrackingMethod: 3) } # ES, Night-by-Night
  let!(:she) do
    create(:she_entry, client: restricted_destination_client, project: project,
                       record_type: :entry, first_date_in_program: 1.year.ago.to_date, last_date_in_program: nil)
  end
  let!(:open_she) do
    create(:she_entry, client: open_destination_client, project: project,
                       record_type: :entry, first_date_in_program: 1.year.ago.to_date, last_date_in_program: nil)
  end
  let(:date_range_params) { { project: { id: project.id, start: 2.years.ago.to_date, end: Date.tomorrow } } }

  # `GrdaWarehouse::Config.get` caches the settings row at the class level for 30 seconds,
  # independent of each example's DB transaction rollback -- without this, an earlier example's
  # `include_pii_in_detail_downloads` change can leak into a later one regardless of run order.
  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  # `.xlsx` responses are a compressed OOXML zip, not plain text -- `response.body.include?` would
  # pass even on unredacted data, since the raw string never appears uncompressed. Parse the actual
  # workbook instead, matching the pattern in `open_enrollments_no_service_controller_spec.rb`.
  def rendered_workbook
    excel_file = Tempfile.new(['client_in_project_during_date_range', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'redacts the restricted client name in the HTML view but shows the unrestricted client name' do
    get warehouse_reports_client_in_project_during_date_range_index_path(date_range_params)

    expect(response.body).not_to include('>Restricted<')
    expect(response.body).not_to include('>RClient<')
    expect(response.body).to include('Name Redacted')
    expect(response.body).to include('>Open<')
    expect(response.body).to include('>OClient<')
  end

  it 'redacts the restricted client name and DOB in the Excel export when the download toggle is on, leaving the unrestricted client intact' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache

    get warehouse_reports_client_in_project_during_date_range_index_path(date_range_params.merge(format: :xlsx))

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    rows = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }

    restricted_row = rows.find { |r| r[0] == restricted_destination_client.id }
    expect(restricted_row[1]).to eq('Name Redacted')
    expect(restricted_row[2]).to eq('Name Redacted')
    expect(restricted_row[3]).to eq('Redacted')

    open_row = rows.find { |r| r[0] == open_destination_client.id }
    expect(open_row[1]).to eq('Open')
    expect(open_row[2]).to eq('OClient')
    expect(Date.parse(open_row[3].to_s)).to eq(Date.new(1990, 1, 1))
  end

  it 'redacts every client name and DOB in the Excel export when the download toggle is off' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
    GrdaWarehouse::Config.invalidate_cache

    get warehouse_reports_client_in_project_during_date_range_index_path(date_range_params.merge(format: :xlsx))

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    rows = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }

    open_row = rows.find { |r| r[0] == open_destination_client.id }
    expect(open_row[1]).to eq('Name Redacted')
    expect(open_row[2]).to eq('Name Redacted')
    expect(open_row[3]).to eq('Redacted')
  end
end
