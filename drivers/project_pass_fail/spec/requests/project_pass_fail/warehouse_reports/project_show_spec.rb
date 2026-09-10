###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ProjectPassFail::WarehouseReports::Project#show', type: :request do
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_clients: true, can_view_client_name: true, can_view_full_ssn: true, can_view_full_dob: true) }
  let!(:user) { create(:acl_user) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Doe') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Doe') }

  let!(:project_data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: project_data_source) }
  let!(:hud_project) { create(:hud_project, data_source: project_data_source, OrganizationID: organization.OrganizationID) }

  let!(:report) { ProjectPassFail::ProjectPassFail.create!(user_id: user.id, options: { 'filters' => {} }) }
  let!(:pf_project) { ProjectPassFail::Project.create!(project_pass_fail: report, project: hud_project, available_beds: 10) }
  let!(:restricted_client) do
    ProjectPassFail::Client.create!(
      project_pass_fail: report,
      project: pf_project,
      client_id: restricted_source_client.id,
      first_name: 'Restricted',
      last_name: 'Client',
      dob: Date.new(1990, 1, 1),
      ssn: '123456789',
      days_served: 10,
    )
  end
  let!(:open_client) do
    ProjectPassFail::Client.create!(
      project_pass_fail: report,
      project: pf_project,
      client_id: open_source_client.id,
      first_name: 'Open',
      last_name: 'Doe',
      dob: Date.new(1985, 6, 15),
      ssn: '987654321',
      days_served: 5,
    )
  end

  # `GrdaWarehouse::Config.get` caches the settings row at the class level for 30 seconds,
  # independent of each example's DB transaction rollback.
  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ projects: [hud_project.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in(user)
  end

  # `.xlsx` responses are a compressed OOXML zip, not plain text — parse the actual
  # workbook, matching the pattern in spec/requests/warehouse_reports/open_enrollments_no_service_controller_spec.rb.
  def rendered_workbook
    excel_file = Tempfile.new(['project_pass_fail', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'redacts the restricted client and shows the unrestricted client in the HTML view' do
    get project_pass_fail_warehouse_reports_project_pass_fail_project_path(report, pf_project)

    expect(response).to have_http_status(:success)
    expect(response.body).not_to include('Restricted')
    expect(response.body).to include(GrdaWarehouse::PiiProvider::NAME_REDACTED)
    expect(response.body).to include('Open')
    expect(response.body).not_to include('123456789')
    expect(response.body).not_to include('1990-01-01')
  end

  it 'redacts the restricted client and shows the unrestricted client in the Excel export when the download toggle is on' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

    get project_pass_fail_warehouse_reports_project_pass_fail_project_path(report, pf_project, format: :xlsx)

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    headers = sheet.row(1)
    first_name_index = headers.index('First Name')
    ssn_index = headers.index('SSN')
    rows = (sheet.first_row + 1..sheet.last_row).map { |i| sheet.row(i) }
    restricted_row = rows.find { |r| r[0] == restricted_destination_client.id }
    open_row = rows.find { |r| r[0] == open_destination_client.id }

    expect(restricted_row[first_name_index]).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
    expect(restricted_row[ssn_index]).to eq(GrdaWarehouse::PiiProvider::REDACTED)
    expect(open_row[first_name_index]).to eq('Open')
    expect(open_row[ssn_index]).to eq('987-65-4321')
  end

  it 'omits PII columns entirely from the Excel export when the download toggle is off' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
    GrdaWarehouse::Config.invalidate_cache

    get project_pass_fail_warehouse_reports_project_pass_fail_project_path(report, pf_project, format: :xlsx)

    expect(response).to have_http_status(:success)
    headers = rendered_workbook.sheet(0).row(1)
    expect(headers & ['First Name', 'Last Name', 'DOB', 'SSN']).to be_empty
  end
end
