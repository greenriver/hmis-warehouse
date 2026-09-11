###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HapReport::WarehouseReports::HapReportsController#details', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:role) { create(:role, can_view_assigned_reports: true) }
  let!(:collection) { create(:collection) }
  let!(:report_def) { create(:touch_point_report, url: 'hap_report/warehouse_reports/hap_reports', name: 'HAP Report') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client') }
  # project_ids must be non-empty: HapReport::Report validates its presence, an array with a bad ID is fine.
  let!(:hap_report) { HapReport::Report.create!(user: user, options: { start: 1.year.ago.to_date, end: Date.current, project_ids: [0] }) }
  let!(:report_cell) { SimpleReports::ReportCell.create!(report_instance: hap_report, name: 'b1') }
  let!(:hap_client) { HapReport::HapClient.create!(client_id: restricted_destination_client.id) }
  let!(:open_hap_client) { HapReport::HapClient.create!(client_id: open_destination_client.id) }
  let!(:member) { SimpleReports::UniverseMember.create!(report_cell: report_cell, client: restricted_destination_client, first_name: 'Restricted', last_name: 'Client', universe_membership: hap_client) }
  let!(:open_member) { SimpleReports::UniverseMember.create!(report_cell: report_cell, client: open_destination_client, first_name: 'Open', last_name: 'Client', universe_membership: open_hap_client) }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_def.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  it 'redacts the restricted client name in the cell detail view' do
    get details_hap_report_warehouse_reports_hap_report_path(hap_report, cell: 'b1')

    expect(response.body).not_to include('Restricted')
    expect(response.body).to include('Name Redacted')
  end

  it 'shows an unrestricted client name in the cell detail view' do
    get details_hap_report_warehouse_reports_hap_report_path(hap_report, cell: 'b1')

    expect(response.body).to include('Open')
    expect(response.body).to include('Client')
  end
end
