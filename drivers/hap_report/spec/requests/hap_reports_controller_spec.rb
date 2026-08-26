###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HapReport::WarehouseReports::HapReportsController#details', type: :request do
  let!(:user) { create(:acl_user) }
  # `can_view_all_reports`/`can_view_assigned_reports` default to `false` on the `:role` factory
  # (it only sets `name: 'role'`, no permission columns) — `SimpleReports::ReportInstance.viewable_by`
  # needs `can_view_assigned_reports?` true plus the report's `user_id` matching, since `hap_report`
  # below is owned by `user`.
  let!(:role) { create(:role, can_view_assigned_reports: true) }
  let!(:collection) { create(:collection) }
  let!(:report_def) { create(:touch_point_report, url: 'hap_report/warehouse_reports/hap_reports', name: 'HAP Report') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  # project_ids must be non-empty: HapReport::Report validates its presence, and an
  # empty array counts as blank.
  let!(:hap_report) { HapReport::Report.create!(user: user, options: { start: 1.year.ago.to_date, end: Date.current, project_ids: [0] }) }
  let!(:report_cell) { SimpleReports::ReportCell.create!(report_instance: hap_report, name: 'b1') }
  # SimpleReports::ReportCell#members joins universe_members to their polymorphic
  # universe_membership record to build the table columns, so the member needs a real
  # universe_membership, not just a client.
  let!(:hap_client) { HapReport::HapClient.create!(client_id: restricted_destination_client.id) }
  let!(:member) { SimpleReports::UniverseMember.create!(report_cell: report_cell, client: restricted_destination_client, first_name: 'Restricted', last_name: 'Client', universe_membership: hap_client) }

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

    # first_name and last_name render in separate table cells, so 'Restricted Client'
    # never appears as contiguous text either way -- check the raw first_name value
    # instead, which does appear verbatim in its own cell when unredacted.
    expect(response.body).not_to include('Restricted')
    expect(response.body).to include('Name Redacted')
  end
end
