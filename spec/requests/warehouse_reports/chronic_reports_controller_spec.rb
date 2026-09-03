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
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
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

  describe 'WarehouseReports::ChronicController#show' do
    let!(:report) { create(:touch_point_report, url: 'warehouse_reports/chronic', name: 'Potentially Chronic Clients') }
    let!(:chronic_report) { create(:chronic_report, parameters: { 'date' => Date.current.to_s, 'filter' => { 'on' => Date.current.to_s } }, data: [client_row(restricted_destination_client, chronic_key: 'chronic')]) }

    before { collection.set_viewables({ reports: [report.id] }) }

    it 'redacts the restricted client name in the html view' do
      get warehouse_reports_chronic_path(chronic_report)

      expect(response.body).not_to include('Restricted Client')
      expect(response.body).to include('Name Redacted')
    end

    it 'redacts the restricted client name and DOB in the Excel export' do
      get warehouse_reports_chronic_path(chronic_report, format: :xlsx)

      expect(response).to have_http_status(:success)
      sheet = rendered_workbook.sheet(0)
      row = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }.find { |r| r[0] == restricted_destination_client.id }
      expect(row[1]).to eq('Name Redacted')
      expect(row[2]).to eq('Name Redacted')
      expect(row[3]).to eq('Redacted')
    end
  end

  describe 'WarehouseReports::HudChronicsController#show' do
    let!(:report) { create(:touch_point_report, url: 'warehouse_reports/hud_chronics', name: 'HUD Chronic Clients') }
    let!(:hud_chronic_report) { create(:hud_chronic_report, parameters: { 'date' => Date.current.to_s, 'filter' => { 'on' => Date.current.to_s } }, data: [client_row(restricted_destination_client, chronic_key: 'hud_chronic')]) }

    before { collection.set_viewables({ reports: [report.id] }) }

    it 'redacts the restricted client name in the html view' do
      get warehouse_reports_hud_chronic_path(hud_chronic_report)

      expect(response.body).not_to include('Restricted Client')
      expect(response.body).to include('Name Redacted')
    end

    it 'redacts the restricted client name and DOB in the Excel export' do
      get warehouse_reports_hud_chronic_path(hud_chronic_report, format: :xlsx)

      expect(response).to have_http_status(:success)
      sheet = rendered_workbook.sheet(0)
      row = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }.find { |r| r[0] == restricted_destination_client.id }
      expect(row[1]).to eq('Name Redacted')
      expect(row[2]).to eq('Name Redacted')
      expect(row[3]).to eq('Redacted')
    end
  end
end
