###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::NonAlphaNamesController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_projects: true, can_view_client_name: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/non_alpha_names', name: 'Non-Alpha Names') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: '1Restricted', last_name: '2Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: '1Restricted', LastName: '2Client') }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: '3Open', last_name: '4Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: '3Open', LastName: '4Client') }
  let!(:organization) { create(:hud_organization, data_source: hmis_ds) }
  let!(:project) { create(:hud_project, data_source: hmis_ds, OrganizationID: organization.OrganizationID, ProjectType: 1, TrackingMethod: 3) } # ES, Night-by-Night
  # `can_view_client_name` is granted per client through the client's enrolled project's
  # collection, so each source client needs a real enrollment in the viewable project --
  # unlike the destination-client `WarehouseClient` link above, which only maps identity.
  let!(:enrollment) { create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(restricted_source_client.id), data_source: hmis_ds, project: project) }
  let!(:open_enrollment) { create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(open_source_client.id), data_source: hmis_ds, project: project) }

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
    excel_file = Tempfile.new(['non_alpha_names', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'redacts the client name for a restricted client but shows the unrestricted client name in the HTML view' do
    get warehouse_reports_non_alpha_names_path

    expect(response.body).not_to include('1Restricted')
    expect(response.body).not_to include('2Client')
    expect(response.body).to include('Name⎵Redacted')
    expect(response.body).to include('4Client')
  end

  it 'redacts the restricted client name in the Excel export and shows the unrestricted client name when the download toggle is on' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache

    get warehouse_reports_non_alpha_names_path(format: :xlsx)

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    rows = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }

    restricted_row = rows.find { |r| r[0].to_s == restricted_destination_client.uuid }
    expect(restricted_row[1]).to eq('Name Redacted')
    expect(restricted_row[2]).to eq('Name Redacted')

    open_row = rows.find { |r| r[0].to_s == open_destination_client.uuid }
    expect(open_row[1]).to eq('3Open')
    expect(open_row[2]).to eq('4Client')
  end

  it 'redacts every client name in the Excel export when the download toggle is off, including the previously-unrestricted client' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
    GrdaWarehouse::Config.invalidate_cache

    get warehouse_reports_non_alpha_names_path(format: :xlsx)

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    rows = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }

    restricted_row = rows.find { |r| r[0].to_s == restricted_destination_client.uuid }
    expect(restricted_row[1]).to eq('Name Redacted')
    expect(restricted_row[2]).to eq('Name Redacted')

    open_row = rows.find { |r| r[0].to_s == open_destination_client.uuid }
    expect(open_row[1]).to eq('Name Redacted')
    expect(open_row[2]).to eq('Name Redacted')
  end
end
