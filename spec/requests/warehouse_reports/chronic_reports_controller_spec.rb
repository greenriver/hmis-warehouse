###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Chronic and HUD Chronic warehouse reports', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restrictedfirst', last_name: 'Restrictedlast') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restrictedfirst', LastName: 'Restrictedlast', DOB: Date.new(1990, 1, 1)) }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Openfirst', last_name: 'Openlast') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Openfirst', LastName: 'Openlast', DOB: Date.new(1985, 6, 15)) }

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  def client_row(client, chronic_key:)
    {
      'id' => client.id,
      'FirstName' => client.FirstName,
      'LastName' => client.LastName,
      'DOB' => client.DOB,
      'age' => 40,
      chronic_key => {
        'homeless_since' => '2020-01-01',
        'days_in_last_three_years' => 400,
        'months_in_last_three_years' => 13,
        'trigger' => nil,
        'dmh' => false,
      },
      'source_disabilities' => '',
      'veteran' => false,
      'so_clients' => [],
      'chronic_project_names' => '',
      'most_recent_service' => nil,
      'data_sources' => '',
      'source_clients' => [{ 'id' => client.id, 'uuid' => SecureRandom.uuid, 'data_source_short_name' => 'DS' }],
    }
  end

  def rendered_workbook
    excel_file = Tempfile.new(['chronic_report', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  def workbook_rows
    sheet = rendered_workbook.sheet(0)
    (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }
  end

  shared_examples 'redacts only the restricted client in the html view' do |path_helper|
    it 'redacts only the restricted client name in the html view' do
      get send(path_helper, report_record)

      expect(response.body).not_to include('Restrictedfirst')
      expect(response.body).not_to include('Restrictedlast')
      expect(response.body).to include('Name Redacted')
      expect(response.body).to include('Openfirst Openlast')
    end
  end

  describe 'WarehouseReports::ChronicController#show' do
    let!(:report) { create(:touch_point_report, url: 'warehouse_reports/chronic', name: 'Potentially Chronic Clients') }
    let!(:report_record) do
      create(
        :chronic_report,
        parameters: { 'date' => Date.current.to_s, 'filter' => { 'on' => Date.current.to_s } },
        data: [client_row(restricted_destination_client, chronic_key: 'chronic'), client_row(open_destination_client, chronic_key: 'chronic')],
      )
    end

    before { collection.set_viewables({ reports: [report.id] }) }

    include_examples 'redacts only the restricted client in the html view', :warehouse_reports_chronic_path

    it 'redacts the restricted client and shows the unrestricted client in the Excel export when the download toggle is on' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

      get warehouse_reports_chronic_path(report_record, format: :xlsx)

      expect(response).to have_http_status(:success)
      rows = workbook_rows
      restricted_row = rows.find { |r| r[0] == restricted_destination_client.id }
      expect(restricted_row[1]).to eq('Name Redacted')
      expect(restricted_row[2]).to eq('Name Redacted')
      expect(restricted_row[3]).to eq('Redacted')

      open_row = rows.find { |r| r[0] == open_destination_client.id }
      expect(open_row[1]).to eq('Openfirst')
      expect(open_row[2]).to eq('Openlast')
      expect(open_row[3].to_date).to eq(Date.new(1985, 6, 15))
    end

    it 'redacts every client in the Excel export when the download toggle is off' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)

      get warehouse_reports_chronic_path(report_record, format: :xlsx)

      expect(response).to have_http_status(:success)
      rows = workbook_rows
      [restricted_destination_client, open_destination_client].each do |client|
        row = rows.find { |r| r[0] == client.id }
        expect(row[1]).to eq('Name Redacted')
        expect(row[2]).to eq('Name Redacted')
        expect(row[3]).to eq('Redacted')
      end
    end
  end

  describe 'WarehouseReports::HudChronicsController#show' do
    let!(:report) { create(:touch_point_report, url: 'warehouse_reports/hud_chronics', name: 'HUD Chronic Clients') }
    let!(:report_record) do
      create(
        :hud_chronic_report,
        parameters: { 'date' => Date.current.to_s, 'filter' => { 'on' => Date.current.to_s } },
        data: [client_row(restricted_destination_client, chronic_key: 'hud_chronic'), client_row(open_destination_client, chronic_key: 'hud_chronic')],
      )
    end

    before { collection.set_viewables({ reports: [report.id] }) }

    include_examples 'redacts only the restricted client in the html view', :warehouse_reports_hud_chronic_path

    it 'redacts the restricted client and shows the unrestricted client in the Excel export when the download toggle is on' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

      get warehouse_reports_hud_chronic_path(report_record, format: :xlsx)

      expect(response).to have_http_status(:success)
      rows = workbook_rows
      expect(rows.first[1..3]).to eq(['First Name', 'Last Name', 'DOB'])

      restricted_row = rows.find { |r| r[0] == restricted_destination_client.id }
      expect(restricted_row[1]).to eq('Name Redacted')
      expect(restricted_row[2]).to eq('Name Redacted')
      expect(restricted_row[3]).to eq('Redacted')

      open_row = rows.find { |r| r[0] == open_destination_client.id }
      expect(open_row[1]).to eq('Openfirst')
      expect(open_row[2]).to eq('Openlast')
      expect(open_row[3].to_date).to eq(Date.new(1985, 6, 15))
    end

    it 'omits the name and DOB columns entirely when the download toggle is off' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)

      get warehouse_reports_hud_chronic_path(report_record, format: :xlsx)

      expect(response).to have_http_status(:success)
      rows = workbook_rows
      header = rows.first
      expect(header).not_to include('First Name', 'Last Name', 'DOB')
      expect(header[1]).to eq('Homeless Since')

      [restricted_destination_client, open_destination_client].each do |client|
        row = rows.find { |r| r[0] == client.id }
        expect(row.size).to eq(header.size)
        expect(row).not_to include('Restrictedfirst', 'Restrictedlast', 'Openfirst', 'Openlast', 'Name Redacted')
      end
    end
  end
end
