###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::IncomesController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) do
    create(
      :role,
      can_view_all_reports: true,
      can_view_assigned_reports: true,
      can_view_projects: true,
      can_view_client_name: true,
      can_view_clients: true,
    )
  end
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/incomes', name: 'Incomes') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Zephyr') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Zephyr') }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client') }
  let!(:project_data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: project_data_source) }
  let!(:project) { create(:hud_project, data_source: project_data_source, OrganizationID: organization.OrganizationID, ProjectType: 1, TrackingMethod: 3) } # ES, Night-by-Night

  let(:entry_date) { 2.years.ago.to_date }
  let(:filter_params) do
    {
      start: 3.years.ago.to_date,
      end: Date.current,
      project_ids: [project.id],
    }
  end

  # `enrollment_source` inner-joins `:enrollment` (a `GrdaWarehouse::Hud::Enrollment`, keyed by
  # `EnrollmentID`/`ProjectID`/`data_source_id`), so each `she_entry` needs a matching `Enrollment`
  # row or its row is filtered out of `@enrollments` entirely.
  def build_enrollment(client:)
    hud_enrollment = create(:hud_enrollment, ProjectID: project.ProjectID, data_source: project_data_source)
    create(:she_entry, client: client, project: project, enrollment_group_id: hud_enrollment.EnrollmentID,
                       record_type: :entry, project_type: 1, first_date_in_program: entry_date, last_date_in_program: nil)
  end

  let!(:restricted_entry) { build_enrollment(client: restricted_destination_client) }
  let!(:open_entry) { build_enrollment(client: open_destination_client) }

  # `after` guards against `GrdaWarehouse::Config.get`'s class-level cache carrying an
  # `include_pii_in_detail_downloads` value from one example's DB transaction into the next.
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
  # workbook instead, matching `open_enrollments_no_service_controller_spec.rb`'s `rendered_workbook`.
  def rendered_workbook
    excel_file = Tempfile.new(['incomes', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'shows the unrestricted client name in the Excel export and redacts the restricted one when the download toggle is on' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

    get warehouse_reports_incomes_path(format: :xlsx, filter: filter_params)

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    rows = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }
    restricted_row = rows.find { |r| r[0] == restricted_destination_client.id }
    open_row = rows.find { |r| r[0] == open_destination_client.id }
    expect(restricted_row[1]).to eq('Name Redacted')
    expect(restricted_row[2]).to eq('Name Redacted')
    expect(open_row[1]).to eq('Open')
    expect(open_row[2]).to eq('Client')
  end

  it 'omits the First Name/Last Name columns from the Excel export when the download toggle is off' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
    GrdaWarehouse::Config.invalidate_cache

    get warehouse_reports_incomes_path(format: :xlsx, filter: filter_params)

    expect(response).to have_http_status(:success)
    header_row = rendered_workbook.sheet(0).row(1)
    expect(header_row).not_to include('First Name')
    expect(header_row).not_to include('Last Name')
  end
end
