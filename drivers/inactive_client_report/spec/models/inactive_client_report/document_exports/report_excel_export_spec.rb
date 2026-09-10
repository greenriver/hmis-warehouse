###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'roo'

RSpec.describe InactiveClientReport::DocumentExports::ReportExcelExport, type: :model do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_projects: true, can_view_client_name: true, can_view_full_dob: true) }
  let!(:report_definition) { create(:touch_point_report, url: InactiveClientReport::Report.url, name: 'Client Activity Report') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:organization) { create(:hud_organization, data_source: hmis_ds) }
  let!(:project) { create(:hud_project, data_source: hmis_ds, OrganizationID: organization.OrganizationID, ProjectType: 1) } # ES

  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'RClient') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'RClient', DOB: '1990-06-15') }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'OClient') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'OClient', DOB: '1990-06-15') }

  # `can_view_client_name`/`can_view_full_dob` are granted per client through the client's
  # enrolled project's collection, so each source client needs a real enrollment in the viewable
  # project -- unlike the `WarehouseClient` link below, which only maps identity.
  let!(:restricted_enrollment) { create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(restricted_source_client.id), data_source: hmis_ds, project: project) }
  let!(:open_enrollment) { create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(open_source_client.id), data_source: hmis_ds, project: project) }

  # `Report#report_scope` keeps only enrollments ongoing on `filter.on`, so the entry must be
  # open (no exit) as of that date.
  let(:on_date) { Date.current }
  let!(:restricted_she) { create(:she_entry, client: restricted_destination_client, project: project, record_type: :entry, project_type: 1, first_date_in_program: 6.months.ago.to_date, last_date_in_program: nil) }
  let!(:open_she) { create(:she_entry, client: open_destination_client, project: project, record_type: :entry, project_type: 1, first_date_in_program: 6.months.ago.to_date, last_date_in_program: nil) }

  let(:query_string) do
    {
      filters: {
        on: on_date.to_s,
        start: 1.year.ago.to_date.to_s,
        end: on_date.to_s,
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
    file = Tempfile.new(['inactive_client_export', '.xlsx'])
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

  it 'redacts the restricted client name and DOB and shows them for the unrestricted client when the download toggle is on' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache

    sheet = generated_sheet
    restricted_row = sheet_row_by_header(sheet, key: restricted_destination_client.id)
    open_row = sheet_row_by_header(sheet, key: open_destination_client.id)

    expect(restricted_row.values_at('Last Name', 'First Name')).to eq(['Name Redacted', 'Name Redacted'])
    expect(restricted_row['DOB']).to be_nil
    expect(open_row.values_at('Last Name', 'First Name')).to eq(['OClient', 'Open'])
    expect(open_row['DOB'].to_date).to eq(Date.new(1990, 6, 15))
  end

  it 'keeps the Age column for both clients when the download toggle is on' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache

    sheet = generated_sheet
    expected_age = GrdaWarehouse::Hud::Client.age(date: Date.current, dob: Date.new(1990, 6, 15))

    expect(sheet_row_by_header(sheet, key: restricted_destination_client.id)['Age'].to_i).to eq(expected_age)
    expect(sheet_row_by_header(sheet, key: open_destination_client.id)['Age'].to_i).to eq(expected_age)
  end

  it 'omits the name and DOB columns for every client when the download toggle is off' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
    GrdaWarehouse::Config.invalidate_cache

    sheet = generated_sheet
    restricted_row = sheet_row_by_header(sheet, key: restricted_destination_client.id)
    open_row = sheet_row_by_header(sheet, key: open_destination_client.id)

    expect(restricted_row.keys).not_to include('Last Name', 'First Name', 'DOB')
    expect(open_row.keys).not_to include('Last Name', 'First Name', 'DOB')
    expect(open_row.keys).to include('Warehouse ID', 'Age', 'Last Seen', 'Ongoing Enrollments')
  end
end
