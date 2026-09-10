###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::FindByIdController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/find_by_id', name: 'Bulk Find Client Details by ID') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client', SSN: '111223333', DOB: Date.new(1990, 1, 1)) }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client', SSN: '999887777', DOB: Date.new(1985, 6, 15)) }

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  def search(ids, format: :html)
    post search_warehouse_reports_find_by_id_index_path(format: format), params: { client: { id: ids.join(', ') } }
  end

  it 'redacts the name, SSN, and DOB of a restricted client in the html table' do
    search([restricted_destination_client.id])

    expect(response.body).not_to include('Restricted')
    expect(response.body).not_to include('111223333')
    expect(response.body).not_to include('111-22-3333')
    expect(response.body).not_to include('1990-01-01')
    expect(response.body).to include('Name Redacted')
  end

  it 'shows an unrestricted client name, SSN, and DOB in the html table' do
    search([open_destination_client.id])

    expect(response.body).to include('Open')
    expect(response.body).to include('999-88-7777')
  end

  def rendered_workbook
    excel_file = Tempfile.new(['find_by_id', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'redacts the name, SSN, and DOB of a restricted client in the Excel export' do
    search([restricted_destination_client.id], format: :xlsx)

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    row = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }.find { |r| r[0] == restricted_destination_client.id }
    expect(row[1]).to eq('Name Redacted')
    expect(row[2]).to eq('Name Redacted')
    expect(row[3]).to eq('Redacted')
    expect(row[4]).to eq('Redacted')
  end

  it 'shows an unrestricted client name, SSN, and DOB in the Excel export' do
    search([open_destination_client.id], format: :xlsx)

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    row = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }.find { |r| r[0] == open_destination_client.id }
    expect(row[1]).to eq('Open')
    expect(row[2]).to eq('Client')
    expect(row[3].to_s).to eq('999-88-7777')
  end
end
