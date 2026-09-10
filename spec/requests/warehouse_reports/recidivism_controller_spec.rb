###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::RecidivismController', type: :request do
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
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/recidivism', name: 'Recidivism') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Zephyr') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Zephyr') }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client') }
  let!(:project_data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: project_data_source) }
  let!(:ph_project) { create(:hud_project, data_source: project_data_source, OrganizationID: organization.OrganizationID, ProjectType: 3) } # PSH
  let!(:es_project) { create(:hud_project, data_source: project_data_source, OrganizationID: organization.OrganizationID, ProjectType: 1) } # ES, Night-by-Night

  # `rows_for_export`'s per-client PII policy resolves through `DestinationClientPolicy` to each
  # source client's own project enrollment (`GrdaWarehouse::Hud::Enrollment`, not the
  # `ServiceHistoryEnrollment` rows the recidivism scope matches on) -- unlike the project-scoped
  # `incomes_controller`, it isn't granted directly from a viewable project. Give the unrestricted
  # source client a real enrollment in a project the collection can view, so its name permission
  # resolves to visible instead of falling through to the deny-by-default policy.
  let!(:permission_project) { create(:hud_project, data_source: hmis_ds) }
  let!(:open_source_enrollment) { create(:hud_enrollment, PersonalID: open_source_client.PersonalID, ProjectID: permission_project.ProjectID, data_source: hmis_ds) }

  let(:move_in_date) { 6.months.ago.to_date }
  let(:es_entry_date) { 3.months.ago.to_date }
  let(:filter_params) { { start: 1.year.ago.to_date, end: Date.current } }

  # The PH enrollment must stay "open" (no `last_date_in_program`) with a `move_in_date`, and the
  # homeless enrollment's `first_date_in_program` must fall after it -- the shape `index`'s
  # `@homeless_clients.delete_if` keeps (see `RecidivismController#index`).
  def build_recidivism_enrollments(client:)
    ph_entry = create(:she_entry, client: client, project: ph_project, project_type: 3, first_date_in_program: 1.year.ago.to_date, last_date_in_program: nil, move_in_date: move_in_date)
    es_entry = create(:she_entry, client: client, project: es_project, project_type: 1, first_date_in_program: es_entry_date, last_date_in_program: nil)
    create(:service_history_service, service_history_enrollment: es_entry, client: client, date: es_entry_date, record_type: 'service')
    [ph_entry, es_entry]
  end

  let!(:restricted_enrollments) { build_recidivism_enrollments(client: restricted_destination_client) }
  let!(:open_enrollments) { build_recidivism_enrollments(client: open_destination_client) }

  # `after` guards against `GrdaWarehouse::Config.get`'s class-level cache carrying an
  # `include_pii_in_detail_downloads` value from one example's DB transaction into the next.
  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id], projects: [ph_project.id, es_project.id, permission_project.id] })
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
    excel_file = Tempfile.new(['recidivism', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'shows the unrestricted client name in the Excel export and redacts the restricted one when the download toggle is on' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

    get warehouse_reports_recidivism_index_path(format: :xlsx, filter: filter_params)

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

    get warehouse_reports_recidivism_index_path(format: :xlsx, filter: filter_params)

    expect(response).to have_http_status(:success)
    header_row = rendered_workbook.sheet(0).row(1)
    expect(header_row).not_to include('First Name')
    expect(header_row).not_to include('Last Name')
  end
end
