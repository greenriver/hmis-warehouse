###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'roo'

RSpec.describe ClientDocumentsReport::DocumentExports::ReportExcelExport, type: :model do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_projects: true, can_view_client_name: true) }
  let!(:report_definition) { create(:touch_point_report, url: ClientDocumentsReport::Report.url, name: 'Client Documents') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:organization) { create(:hud_organization, data_source: hmis_ds) }
  let!(:project) { create(:hud_project, data_source: hmis_ds, OrganizationID: organization.OrganizationID, ProjectType: 1) } # ES

  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'RClient') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'RClient') }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'OClient') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'OClient') }

  # `can_view_client_name` is granted per client through the client's enrolled project's
  # collection, so each source client needs a real enrollment in the viewable project --
  # unlike the `WarehouseClient` link below, which only maps identity.
  let!(:restricted_enrollment) { create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(restricted_source_client.id), data_source: hmis_ds, project: project) }
  let!(:open_enrollment) { create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(open_source_client.id), data_source: hmis_ds, project: project) }

  # `Report#clients` selects destination clients through `ServiceHistoryEnrollment` entry rows
  # matched by the filter's date range and `project_ids`.
  let!(:restricted_she) { create(:she_entry, client: restricted_destination_client, project: project, record_type: :entry, project_type: 1, first_date_in_program: 6.months.ago.to_date, last_date_in_program: nil) }
  let!(:open_she) { create(:she_entry, client: open_destination_client, project: project, record_type: :entry, project_type: 1, first_date_in_program: 6.months.ago.to_date, last_date_in_program: nil) }

  let(:query_string) do
    {
      filters: {
        start: 1.year.ago.to_date.to_s,
        end: Date.current.to_s,
        project_ids: [project.id],
        require_service_during_range: 'false',
      },
    }.to_query
  end
  let(:export) { described_class.new(user_id: user.id, query_string: query_string) }

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
  end

  def generated_sheet
    export.perform
    expect(export.status).to eq(GrdaWarehouse::DocumentExport::COMPLETED_STATUS)
    file = Tempfile.new(['client_documents_export', '.xlsx'])
    file.binmode
    file.write(export.file_data)
    file.close
    Roo::Excelx.new(file.path).sheet(0)
  ensure
    file&.unlink
  end

  it 'is authorized for a user with report and project access' do
    expect(export.authorized?).to eq(true)
  end

  it 'redacts the restricted client name and shows the unrestricted client name when the download toggle is on' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache

    sheet = generated_sheet
    restricted_row = sheet_row_by_header(sheet, key: restricted_destination_client.id)
    open_row = sheet_row_by_header(sheet, key: open_destination_client.id)

    expect(restricted_row.values_at('Last Name', 'First Name')).to eq(['Name Redacted', 'Name Redacted'])
    expect(open_row.values_at('Last Name', 'First Name')).to eq(['OClient', 'Open'])
  end

  it 'omits the name columns for every client when the download toggle is off' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
    GrdaWarehouse::Config.invalidate_cache

    sheet = generated_sheet
    restricted_row = sheet_row_by_header(sheet, key: restricted_destination_client.id)
    open_row = sheet_row_by_header(sheet, key: open_destination_client.id)

    expect(restricted_row.keys).not_to include('Last Name', 'First Name')
    expect(open_row.keys).not_to include('Last Name', 'First Name')
    expect(open_row.keys).to include('Warehouse ID', 'Required Documents', 'Optional Documents', 'All Documents')
  end
end
