###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BuiltForZeroReport::WarehouseReports::Bfz#details', type: :request do
  let!(:role) { create(:role, can_view_all_reports: true, can_view_clients: true, can_view_client_name: true) }
  let!(:user) do
    user = create(:user)
    user.legacy_roles << role
    user
  end

  let!(:adult_only_cohort) { GrdaWarehouse::SystemCohorts::AdultOnly.create!(name: 'Adults', days_of_inactivity: 90) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Doe') }

  before do
    allow_any_instance_of(BuiltForZeroReport::WarehouseReports::BfzController).to receive(:report_visible?).and_return(true)
    allow_any_instance_of(BuiltForZeroReport::Calculator).to receive(:source_data).and_return(
      {
        restricted_destination_client.id => { client_id: restricted_destination_client.id, first_name: 'Restricted', last_name: 'Client', change: 'create', reason: 'Newly identified', changed_at: Date.current },
        open_destination_client.id => { client_id: open_destination_client.id, first_name: 'Open', last_name: 'Doe', change: 'create', reason: 'Newly identified', changed_at: Date.current },
      },
    )
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in(user)
  end

  it 'redacts the restricted client and shows the unrestricted client' do
    get details_built_for_zero_report_warehouse_reports_bfz_index_path(report: { section: 'adults', key: 'actively_homeless' })

    expect(response).to have_http_status(:success)
    expect(response.body).not_to include('Restricted')
    expect(response.body).to include(GrdaWarehouse::PiiProvider::NAME_REDACTED)
    expect(response.body).to include('Open')
  end
end
