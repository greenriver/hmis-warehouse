###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'DataQualityReportsController#support', type: :request do
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_clients: true, can_view_client_name: true, can_view_projects: true) }
  let!(:user) { create(:acl_user) }

  let!(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
      url: 'warehouse_reports/project/data_quality',
      name: 'Project Data Quality',
      report_group: 'Reports',
      description: 'Project Data Quality',
    )
  end

  let!(:project_data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: project_data_source) }
  let!(:project) { create(:hud_project, data_source: project_data_source, OrganizationID: organization.OrganizationID) }
  let!(:report) { create(:data_quality_report_version_five, project: project) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Doe') }

  let(:support_data) do
    {
      headers: ['Client ID', 'First Name', 'Last Name', 'DOB', 'SSN'],
      counts: [
        [restricted_destination_client.id, 'Restricted', 'Client', Date.new(1990, 1, 1), '123-45-6789'],
        [open_destination_client.id, 'Open', 'Doe', Date.new(1985, 6, 15), '987-65-4321'],
      ],
      title: 'Test Support',
    }
  end

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    allow_any_instance_of(GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionFive).to receive(:support_for).and_return(support_data)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in(user)
  end

  it 'redacts the restricted client and shows the unrestricted client in the HTML view' do
    get support_project_data_quality_report_path(project, report, individual: true, method: 'test')

    expect(response).to have_http_status(:success)
    expect(response.body).not_to include('Restricted')
    expect(response.body).to include(GrdaWarehouse::PiiProvider::NAME_REDACTED)
    expect(response.body).to include('Open')
  end

  it 'redacts the restricted client and shows the unrestricted client in the Excel export' do
    get support_project_data_quality_report_path(project, report, individual: true, method: 'test', format: :xlsx)

    expect(response).to have_http_status(:success)
    excel_file = Tempfile.new(['data_quality_support', '.xlsx'])
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
