###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AdHocDataSources::UploadsController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:role) do
    create(
      :role,
      can_manage_ad_hoc_data_sources: true,
      can_view_clients: true,
      can_view_client_name: true,
      can_view_full_dob: true,
      can_view_full_ssn: true,
    )
  end
  let!(:collection) { Collection.system_collection(:data_sources) }
  let!(:data_source) { create(:ad_hoc_data_source) }
  let!(:batch) { create(:ad_hoc_batch_valid) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:unrestricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:unrestricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client') }

  let!(:restricted_row) { GrdaWarehouse::AdHocClient.create!(batch_id: batch.id, first_name: 'Restricted', last_name: 'Client', client_id: restricted_destination_client.id, ssn: '111223333', dob: Date.new(1990, 1, 1)) }
  let!(:open_row) { GrdaWarehouse::AdHocClient.create!(batch_id: batch.id, first_name: 'Open', last_name: 'Client', client_id: unrestricted_destination_client.id) }

  before do
    Collection.maintain_system_groups
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: unrestricted_destination_client.id, source_id: unrestricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: unrestricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  it 'redacts the matched name for a restricted client and shows the unrestricted client normally' do
    get ad_hoc_data_source_upload_path(data_source, batch)

    expect(response.body).not_to include('Restricted')
    expect(response.body).to include('Name Redacted')
    expect(response.body).to include('Open')
  end

  # `PiiProvider#ssn` masks to the last four digits rather than a bare "Redacted" string when the
  # viewer can't see the full number (matching `#dob`/`#full_name`'s policy), but the *full* raw
  # SSN/DOB must never appear for a restricted client either way.
  it 'masks the SSN and DOB for a restricted matched client' do
    get ad_hoc_data_source_upload_path(data_source, batch)

    expect(response.body).not_to include('111223333')
    expect(response.body).not_to include('111-22-3333')
    expect(response.body).not_to include('1990-01-01')
  end

  context 'when the user lacks client PII view permissions' do
    let!(:role) { create(:role, can_manage_ad_hoc_data_sources: true) }

    it 'redacts an otherwise-unrestricted matched client' do
      get ad_hoc_data_source_upload_path(data_source, batch)

      expect(response.body).to include('Name Redacted')
      expect(response.body).not_to include('1999-12-01')
    end
  end
end
