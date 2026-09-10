###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::ClientDetails', type: :request do
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

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client') }
  let!(:project_data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: project_data_source) }
  let!(:project) { create(:hud_project, data_source: project_data_source, OrganizationID: organization.OrganizationID, ProjectType: 1, TrackingMethod: 3) } # ES, Night-by-Night

  let(:filter_start) { 3.years.ago.to_date }
  let(:filter_end) { Date.current }
  let(:filter_params) do
    {
      start: filter_start,
      end: filter_end,
      project_type_codes: ['es'],
    }
  end

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
    excel_file = Tempfile.new(['client_details_report', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  describe 'Entries' do
    let!(:report) { create(:touch_point_report, url: 'warehouse_reports/client_details/entries', name: 'Entries') }
    let!(:restricted_entry) do
      create(:she_entry, client: restricted_destination_client, project: project,
                         record_type: :entry, project_type: 1, first_date_in_program: 2.years.ago.to_date, last_date_in_program: nil)
    end
    let!(:open_entry) do
      create(:she_entry, client: open_destination_client, project: project,
                         record_type: :entry, project_type: 1, first_date_in_program: 2.years.ago.to_date, last_date_in_program: nil)
    end

    before do
      [restricted_entry, open_entry].each do |enrollment|
        create(
          :service_history_service,
          service_history_enrollment: enrollment,
          record_type: 200,
          date: 2.years.ago.to_date,
          client_id: enrollment.client_id,
          project_type: enrollment.project_type,
        )
      end
    end

    it 'redacts the restricted client name in the HTML section while showing the unrestricted client name' do
      get section_warehouse_reports_client_details_entries_path(filter: filter_params)

      expect(response.body).not_to include('Restricted Client')
      expect(response.body).to include('Name Redacted')
      expect(response.body).to include('Open Client')
    end

    it 'shows the unrestricted client name in the Excel export and redacts the restricted one when the download toggle is on' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

      get warehouse_reports_client_details_entries_path(format: :xlsx, filter: filter_params)

      expect(response).to have_http_status(:success)
      rows = (rendered_workbook.sheet(0).first_row..rendered_workbook.sheet(0).last_row).map { |i| rendered_workbook.sheet(0).row(i) }
      restricted_row = rows.find { |r| r[0] == restricted_destination_client.id }
      open_row = rows.find { |r| r[0] == open_destination_client.id }
      expect(restricted_row[1]).to eq('Name Redacted')
      expect(restricted_row[2]).to eq('Name Redacted')
      expect(open_row[1]).to eq('Open')
      expect(open_row[2]).to eq('Client')
    end

    it 'redacts every client name in the Excel export when the download toggle is off' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
      GrdaWarehouse::Config.invalidate_cache

      get warehouse_reports_client_details_entries_path(format: :xlsx, filter: filter_params)

      expect(response).to have_http_status(:success)
      sheet = rendered_workbook.sheet(0)
      rows = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }
      open_row = rows.find { |r| r[0] == open_destination_client.id }
      expect(open_row[1]).to eq('Name Redacted')
      expect(open_row[2]).to eq('Name Redacted')
    end
  end

  describe 'Exits' do
    let!(:report) { create(:touch_point_report, url: 'warehouse_reports/client_details/exits', name: 'Exits') }
    let!(:restricted_exit) do
      create(:she_entry, client: restricted_destination_client, project: project,
                         record_type: :exit, project_type: 1, date: 2.years.ago.to_date,
                         first_date_in_program: 2.years.ago.to_date - 30.days, last_date_in_program: 2.years.ago.to_date, destination: 3)
    end
    let!(:open_exit) do
      create(:she_entry, client: open_destination_client, project: project,
                         record_type: :exit, project_type: 1, date: 2.years.ago.to_date,
                         first_date_in_program: 2.years.ago.to_date - 30.days, last_date_in_program: 2.years.ago.to_date, destination: 3)
    end

    it 'redacts the restricted client name in the HTML section while showing the unrestricted client name' do
      restricted_exit
      open_exit

      get section_warehouse_reports_client_details_exits_path(filter: filter_params)

      expect(response.body).not_to include('Restricted Client')
      expect(response.body).to include('Name Redacted')
      expect(response.body).to include('Open Client')
    end

    it 'shows the unrestricted client name in the Excel export and redacts the restricted one when the download toggle is on' do
      restricted_exit
      open_exit
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

      get warehouse_reports_client_details_exits_path(format: :xlsx, filter: filter_params)

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

    it 'redacts every client name in the Excel export when the download toggle is off' do
      restricted_exit
      open_exit
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
      GrdaWarehouse::Config.invalidate_cache

      get warehouse_reports_client_details_exits_path(format: :xlsx, filter: filter_params)

      expect(response).to have_http_status(:success)
      sheet = rendered_workbook.sheet(0)
      rows = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }
      open_row = rows.find { |r| r[0] == open_destination_client.id }
      expect(open_row[1]).to eq('Name Redacted')
      expect(open_row[2]).to eq('Name Redacted')
    end
  end
end
