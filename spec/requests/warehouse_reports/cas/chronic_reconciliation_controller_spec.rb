###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# The controller's @missing_in_cas query ("Chronic Clients ... Not Flagged for CAS")
# merges `site_chronic_source.on_date(date: @date)`, but `@date` is never assigned, so
# that half of the report always returns no rows regardless of fixtures -- untestable
# through the controller action. This spec covers the other half (@not_on_list, AR clients).
RSpec.describe 'WarehouseReports::Cas::ChronicReconciliationController#index', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/cas/chronic_reconciliation', name: 'Chronic Reconciliation') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  # Flagged for CAS (sync_with_cas) but not on the chronic list -- appears in the
  # "Flagged for CAS, Not in Chronic List" half of the report (AR client rows).
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client', sync_with_cas: true) }

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  it 'redacts the restricted client name in the "not in chronic list" AR-client list' do
    get warehouse_reports_cas_chronic_reconciliation_index_path

    expect(response.body).not_to include('Restricted Client')
    expect(response.body).to include('Name Redacted')
  end
end
