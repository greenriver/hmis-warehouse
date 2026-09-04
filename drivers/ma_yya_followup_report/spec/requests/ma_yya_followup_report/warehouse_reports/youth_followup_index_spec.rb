###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MaYyaFollowupReport::WarehouseReports::YouthFollowup#index', type: :request do
  let!(:role) { create(:role, can_view_all_reports: true, can_view_clients: true, can_view_client_name: true) }
  let!(:user) do
    user = create(:user)
    user.legacy_roles << role
    user
  end

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:window_data_source) { create(:visible_data_source) }
  let!(:open_source_client) { create(:hud_client, data_source: window_data_source, FirstName: 'Open', LastName: 'Doe') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Doe') }

  before do
    allow_any_instance_of(MaYyaFollowupReport::WarehouseReports::YouthFollowupController).to receive(:report_visible?).and_return(true)
    allow_any_instance_of(MaYyaFollowupReport::Report).to receive(:clients).and_return(
      [
        { id: restricted_destination_client.id, first_name: 'Restricted', last_name: 'Client', engagement_date: Date.current, last_seen: nil },
        { id: open_destination_client.id, first_name: 'Open', last_name: 'Doe', engagement_date: Date.current, last_seen: nil },
      ],
    )
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: window_data_source.id, id_in_source: open_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in(user)
  end

  it 'redacts the restricted client and shows the unrestricted client' do
    get ma_yya_followup_report_warehouse_reports_youth_followup_index_path

    expect(response).to have_http_status(:success)
    expect(response.body).not_to include('Restricted')
    expect(response.body).to include(GrdaWarehouse::PiiProvider::NAME_REDACTED)
    expect(response.body).to include('Open Doe')
  end
end
