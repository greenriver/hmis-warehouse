###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::ClientsController, type: :request do
  let(:destination_ds) { create(:destination_data_source) }
  let(:source_ds) { create(:visible_data_source) }
  let(:user) { create(:user) }
  let(:destination_client) { create(:hud_client, data_source_id: destination_ds.id) }
  let!(:source_client) { create(:hud_client, FirstName: 'Zzfirst', LastName: 'Zzlast', PersonalID: 'ZzPID-visible', data_source_id: source_ds.id) }

  before do
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: source_client.id, data_source_id: source_ds.id, id_in_source: source_client.PersonalID)
    sign_in user
  end

  def client_audit_rows(client)
    ActivityLog.where(item_model: 'GrdaWarehouse::Hud::Client', item_id: client.id, client_id: client.id)
  end

  context 'when the user has no role granting client access' do
    it 'returns 404 for the destination client id without rendering names' do
      get api_client_path(destination_client)

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include(source_client.FirstName)
    end

    it 'returns 404 for the source client id without rendering names' do
      get api_client_path(source_client)

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include(source_client.FirstName)
    end
  end

  context 'when the user can view clients and names' do
    before { user.legacy_roles << create(:role, can_view_clients: true, can_view_client_name: true) }

    it 'omits a source client from a data source the user cannot see' do
      hidden_ds = create(:source_data_source)
      hidden_source = create(:hud_client, FirstName: 'Zzhiddenfirst', LastName: 'Zzhiddenlast', PersonalID: 'ZzPID-hidden', data_source_id: hidden_ds.id)
      GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: hidden_source.id, data_source_id: hidden_ds.id, id_in_source: hidden_source.PersonalID)

      get api_client_path(destination_client)

      expect(response.body).to include('ZzPID-visible', 'Zzfirst')
      expect(response.body).not_to include('ZzPID-hidden')
      expect(response.body).not_to include('Zzhiddenfirst')
      expect(response.body).not_to include('Zzhiddenlast')
    end

    it 'shows the source client name and logs the destination client' do
      expect { get api_client_path(destination_client) }.to change { client_audit_rows(destination_client).count }.by(1)

      expect(response.body).to include('Zzfirst', 'Zzlast', source_client.PersonalID)
    end

    it 'logs the destination client when the source client id is requested' do
      expect { get api_client_path(source_client) }.to change { client_audit_rows(destination_client).count }.by(1)

      expect(response.body).to include('Zzfirst')
    end

    it 'returns 404 for a visible source client with no destination' do
      orphan = create(:hud_client, data_source_id: source_ds.id)

      get api_client_path(orphan)

      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when the user can view clients but not names' do
    before { user.legacy_roles << create(:role, can_view_clients: true, can_view_client_name: false) }

    it 'redacts the name but keeps the personal id and data source' do
      get api_client_path(destination_client)

      expect(response.body).to include(source_client.PersonalID, GrdaWarehouse::PiiProvider::NAME_REDACTED, "ds-color-#{source_ds.id}")
      expect(response.body).not_to include('Zzfirst')
      expect(response.body).not_to include('Zzlast')
    end
  end

  context 'when another client in the identity is restricted in HMIS' do
    let(:hmis_ds) { create(:hmis_primary_data_source) }
    let(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
    let!(:hmis_source) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Zzrestrict', last_name: 'Zzhidden') }

    before do
      user.legacy_roles << create(:role, can_view_clients: true, can_view_client_name: true)
      user.add_viewable(hmis_ds)
      GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: hmis_source.id, data_source_id: hmis_ds.id, id_in_source: hmis_source.id.to_s)
      hmis_source.mark_as_restricted!(user: hmis_user)
    end

    it 'redacts names in both the restricted and the unrestricted source rows' do
      get api_client_path(destination_client)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(source_client.PersonalID)
      expect(response.body.scan(GrdaWarehouse::PiiProvider::NAME_REDACTED).size).to eq(4)
      expect(response.body).not_to include('Zzfirst')
      expect(response.body).not_to include('Zzrestrict')
    end
  end
end
