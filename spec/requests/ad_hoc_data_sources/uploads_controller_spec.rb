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
  let!(:batch) { create(:ad_hoc_batch_valid, ad_hoc_data_source: data_source) }

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

  # `update_client_ids` used to write any typed id straight through, so a row could hold a
  # `client_id` with no matching `Client`. The page must render that row from its own
  # uploaded values instead of raising on the missing match.
  context 'when a row holds a client_id that no client has' do
    let!(:dangling_row) { GrdaWarehouse::AdHocClient.create!(batch_id: batch.id, first_name: 'Dangling', last_name: 'Row', client_id: 999_999_999) }

    it 'renders the row from its uploaded values and offers the client id input' do
      get ad_hoc_data_source_upload_path(data_source, batch)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Dangling')
      expect(response.body).to include('No match found')
      expect(response.body).to include("clients[#{dangling_row.id}][client_id]")
    end
  end

  describe 'PATCH update' do
    let!(:unmatched_row) { GrdaWarehouse::AdHocClient.create!(batch_id: batch.id, ad_hoc_data_source_id: data_source.id, first_name: 'Unmatched', last_name: 'Row') }
    # A row can only be linked to a client the user can search for or view; the enrollment
    # puts the source client in a project the user's data source collection covers.
    let!(:project) { create(:grda_warehouse_hud_project, data_source: hmis_ds) }
    let!(:enrollment) { create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(unrestricted_source_client.id), data_source: hmis_ds, project: project) }
    let!(:hidden_client) { create(:grda_warehouse_hud_client, FirstName: 'Hidden', LastName: 'Client') }

    it 'links the row to an existing client' do
      patch ad_hoc_data_source_upload_path(data_source, batch), params: { clients: { unmatched_row.id => { client_id: unrestricted_destination_client.id } } }

      expect(unmatched_row.reload.client_id).to eq(unrestricted_destination_client.id)
    end

    it 'ignores a client id that no client has' do
      patch ad_hoc_data_source_upload_path(data_source, batch), params: { clients: { unmatched_row.id => { client_id: 999_999_999 } } }

      expect(unmatched_row.reload.client_id).to be_nil
    end

    it 'ignores a client the user can neither search for nor view' do
      patch ad_hoc_data_source_upload_path(data_source, batch), params: { clients: { unmatched_row.id => { client_id: hidden_client.id } } }

      expect(unmatched_row.reload.client_id).to be_nil
    end
  end

  describe 'GET download' do
    it 'names the matched clients export after the batch' do
      get download_ad_hoc_data_source_upload_path(data_source, batch, matched: true, format: :xlsx)

      expect(response.headers['Content-Disposition']).to start_with('attachment; filename="Ad-Hoc Batch - Matched Clients.xlsx"')
    end

    it 'names the all clients export after the batch' do
      get download_ad_hoc_data_source_upload_path(data_source, batch, all: true, format: :xlsx)

      expect(response.headers['Content-Disposition']).to start_with('attachment; filename="Ad-Hoc Batch - All Clients.xlsx"')
    end
  end

  context 'when the user lacks client PII view permissions' do
    let!(:role) { create(:role, can_manage_ad_hoc_data_sources: true) }

    it 'redacts an otherwise-unrestricted matched client' do
      get ad_hoc_data_source_upload_path(data_source, batch)

      expect(response.body).to include('Name Redacted')
      expect(response.body).not_to include('1999-12-01')
    end
  end

  it 'does not route GET to the upload list' do
    expect { Rails.application.routes.recognize_path("/ad_hoc_data_sources/#{data_source.id}/uploads", method: :get) }.
      to raise_error(ActionController::RoutingError)
  end

  describe 'health priority' do
    let!(:outside_client) { create(:grda_warehouse_hud_client, FirstName: 'Outside', LastName: 'Client') }
    let!(:possible_client) { create(:grda_warehouse_hud_client, FirstName: 'Possible', LastName: 'Match') }

    before { open_row.update!(matching_client_ids: [possible_client.id]) }

    def prioritize(client_ids)
      patch ad_hoc_data_source_upload_path(data_source, batch), params: {
        clients: client_ids.to_h { |id| [id.to_s, { health_prioritized: '1' }] },
      }
    end

    it 'prioritizes a matched client and a possible match from this upload' do
      prioritize([unrestricted_destination_client.id, possible_client.id])

      expect([unrestricted_destination_client.reload.health_prioritized, possible_client.reload.health_prioritized]).to eq(['Yes', 'Yes'])
    end

    it 'ignores a client who is not in this upload' do
      prioritize([outside_client.id])

      expect(outside_client.reload.health_prioritized).to be_nil
    end

    it 'clears priority for a client in this upload but not for one outside it' do
      unrestricted_destination_client.update!(health_prioritized: 'Yes')
      outside_client.update!(health_prioritized: 'Yes')

      patch ad_hoc_data_source_upload_path(data_source, batch), params: {
        clients: [unrestricted_destination_client.id, outside_client.id].to_h { |id| [id.to_s, { health_prioritized: '0' }] },
      }

      expect([unrestricted_destination_client.reload.health_prioritized, outside_client.reload.health_prioritized]).to eq([nil, 'Yes'])
    end
  end

  describe 'an upload from another data source' do
    let(:owner) { create(:acl_user) }
    let(:own_source) { create(:ad_hoc_data_source, user_id: owner.id) }
    let!(:own_batch) { create(:ad_hoc_batch_valid, ad_hoc_data_source: own_source, user_id: owner.id) }

    before do
      setup_access_control(owner, create(:role, can_manage_own_ad_hoc_data_sources: true), create(:collection))
      sign_in owner
    end

    it 'is not found when shown through the user\'s own data source' do
      get ad_hoc_data_source_upload_path(own_source, batch)

      expect(response).to have_http_status(:not_found)
    end

    it 'is not found when its original file is downloaded through the user\'s own data source' do
      get download_ad_hoc_data_source_upload_path(own_source, batch)

      expect(response).to have_http_status(:not_found)
    end

    it 'is not deleted through the user\'s own data source' do
      expect { delete ad_hoc_data_source_upload_path(own_source, batch) }.
        not_to(change { GrdaWarehouse::AdHocBatch.where(id: batch.id).count })
    end

    it 'is not updated through the user\'s own data source' do
      patch ad_hoc_data_source_upload_path(own_source, batch), params: {
        clients: { unrestricted_destination_client.id.to_s => { health_prioritized: '1' } },
      }

      expect(response).to have_http_status(:not_found)
      expect(unrestricted_destination_client.reload.health_prioritized).to be_nil
    end

    it 'still shows the user\'s own upload' do
      get ad_hoc_data_source_upload_path(own_source, own_batch)

      expect(response).to have_http_status(:ok)
    end

    it 'still deletes the user\'s own upload' do
      expect { delete ad_hoc_data_source_upload_path(own_source, own_batch) }.
        to change { GrdaWarehouse::AdHocBatch.where(id: own_batch.id).count }.from(1).to(0)
    end
  end
end
