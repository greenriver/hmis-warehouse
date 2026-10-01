###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::ReEntryController', type: :request do
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
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/re_entry', name: 'Re-Entry') }

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
      project_type_codes: ['es'],
    }
  end

  let!(:restricted_entry) do
    create(:she_entry, client: restricted_destination_client, project: project,
                       record_type: :entry, project_type: 1, first_date_in_program: entry_date, last_date_in_program: nil)
  end
  let!(:open_entry) do
    create(:she_entry, client: open_destination_client, project: project,
                       record_type: :entry, project_type: 1, first_date_in_program: entry_date, last_date_in_program: nil)
  end

  # `re_entry_controller` filters against `Reporting::MonthlyReports::Base.class_for(@filter.sub_population).re_entry`,
  # a precomputed reporting row keyed to the enrollment, not the raw HUD enrollment itself. `days_since_last_exit`
  # above 60 is what the `re_entry` scope selects on (see `MonthlyReportCharts#re_entry`).
  def build_re_entry_report_row(enrollment:, client:)
    Reporting::MonthlyReports::Base.class_for(:clients).create!(
      enrollment_id: enrollment.id,
      client_id: client.id,
      project_id: project.id,
      organization_id: organization.id,
      project_type: 1,
      entry_date: entry_date,
      days_since_last_exit: 90,
      prior_exit_project_type: 8,
      prior_exit_destination_id: 3,
      month: entry_date.month,
      year: entry_date.year,
      mid_month: entry_date,
      calculated_at: Time.zone.now,
    )
  end

  let!(:restricted_report_row) { build_re_entry_report_row(enrollment: restricted_entry, client: restricted_destination_client) }
  let!(:open_report_row) { build_re_entry_report_row(enrollment: open_entry, client: open_destination_client) }

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
  # workbook instead, matching `open_enrollments_no_service_controller_spec.rb`'s `rendered_workbook`.
  def rendered_workbook
    excel_file = Tempfile.new(['re_entry', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'redacts the restricted client name in the HTML view while showing the unrestricted client name' do
    get warehouse_reports_re_entry_index_path(filter: filter_params)

    expect(response.body).not_to include('Restricted')
    expect(response.body).not_to include('Zephyr')
    expect(response.body).to include('Name Redacted')

    # 'Open'/'Client' each also appear in this page's boilerplate (site title, page heading),
    # so the unrestricted client's name is asserted from its own table row's cell text, not
    # the response body as a whole.
    doc = Nokogiri::HTML(response.body)
    open_client_row = doc.css('tbody tr').find { |tr| tr.at_css(%(a[href*="/clients/#{open_destination_client.id}/"])) }
    expect(open_client_row).not_to be_nil
    row_cell_texts = open_client_row.css('td').map { |td| td.text.strip }
    expect(row_cell_texts).to include('Open')
    expect(row_cell_texts).to include('Client')
  end

  it 'shows the unrestricted client name in the Excel export and redacts the restricted one when the download toggle is on' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

    get warehouse_reports_re_entry_index_path(format: :xlsx, filter: filter_params)

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

    get warehouse_reports_re_entry_index_path(format: :xlsx, filter: filter_params)

    expect(response).to have_http_status(:success)
    header_row = rendered_workbook.sheet(0).row(1)
    expect(header_row).not_to include('First Name')
    expect(header_row).not_to include('Last Name')
  end
end
