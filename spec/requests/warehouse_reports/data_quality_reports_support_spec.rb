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

  after { GrdaWarehouse::Config.invalidate_cache }

  def configure_download_toggle(enabled)
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: enabled)
    GrdaWarehouse::Config.invalidate_cache
  end

  def table_cells
    Nokogiri::HTML(response.body).css('table.table-hover tbody td').map { |td| td.text.strip }
  end

  def xlsx_rows
    excel_file = Tempfile.new(['data_quality_support', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    sheet = Roo::Excelx.new(excel_file.path).sheet(0)
    (sheet.first_row + 1..sheet.last_row).map { |i| sheet.row(i) }
  ensure
    excel_file&.unlink
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

  it 'redacts the restricted client name, DOB, and SSN and shows the unrestricted client in the HTML view' do
    get support_project_data_quality_report_path(project, report, individual: true, method: 'test')

    expect(response).to have_http_status(:success)
    cells = table_cells
    expect(cells).to include('Open', 'Doe', '987-65-4321')
    expect(cells.join(' ')).to include('1985')
    expect(cells).not_to include('Restricted', 'Client', '123-45-6789')
    expect(cells.join(' ')).not_to include('1990')
    expect(cells.count(GrdaWarehouse::PiiProvider::NAME_REDACTED)).to eq(2)
    expect(cells.count(GrdaWarehouse::PiiProvider::REDACTED)).to eq(2)
  end

  context 'in the Excel export' do
    it 'redacts only the restricted client when include_pii_in_detail_downloads is on' do
      configure_download_toggle(true)

      get support_project_data_quality_report_path(project, report, individual: true, method: 'test', format: :xlsx)

      expect(response).to have_http_status(:success)
      rows = xlsx_rows
      restricted_row = rows.find { |r| r[0] == restricted_destination_client.id }
      open_row = rows.find { |r| r[0] == open_destination_client.id }

      expect(restricted_row[1..4]).to eq([GrdaWarehouse::PiiProvider::NAME_REDACTED, GrdaWarehouse::PiiProvider::NAME_REDACTED, GrdaWarehouse::PiiProvider::REDACTED, GrdaWarehouse::PiiProvider::REDACTED])
      expect(open_row[1..2]).to eq(['Open', 'Doe'])
      expect(open_row[3].to_date).to eq(Date.new(1985, 6, 15))
      expect(open_row[4]).to eq('987-65-4321')
    end

    it 'redacts every client when include_pii_in_detail_downloads is off' do
      configure_download_toggle(false)

      get support_project_data_quality_report_path(project, report, individual: true, method: 'test', format: :xlsx)

      expect(response).to have_http_status(:success)
      rows = xlsx_rows
      open_row = rows.find { |r| r[0] == open_destination_client.id }

      expect(open_row[0]).to eq(open_destination_client.id)
      expect(open_row[1..4]).to eq([GrdaWarehouse::PiiProvider::NAME_REDACTED, GrdaWarehouse::PiiProvider::NAME_REDACTED, GrdaWarehouse::PiiProvider::REDACTED, GrdaWarehouse::PiiProvider::REDACTED])
    end
  end
end
