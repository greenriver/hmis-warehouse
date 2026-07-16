###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientsController, '#create external data sharing', type: :request do
  let(:source_ds) { create(:source_data_source) }
  let(:user)      { create(:user) }

  let(:base_params) do
    {
      client: {
        FirstName: 'Jane',
        LastName: 'Doe',
        DOB: '1990-01-01',
        SSN: '123-45-6789',
        data_source_id: source_ds.id,
      },
    }
  end

  before do
    user.legacy_roles << create(:can_create_clients)
    create(:destination_data_source)
    sign_in user
  end

  def stub_exclusion_config(value)
    allow(GrdaWarehouse::Config).to receive(:get).and_call_original
    allow(GrdaWarehouse::Config).to receive(:get).
      with(:enable_external_data_sharing_exclusion).
      and_return(value)
  end

  def created_destination
    source = GrdaWarehouse::Hud::Client.where(data_source: source_ds).last
    GrdaWarehouse::WarehouseClient.find_by(source_id: source.id).destination
  end

  def created_source
    GrdaWarehouse::Hud::Client.where(data_source: source_ds).last
  end

  context 'when config is enabled' do
    before { stub_exclusion_config(true) }

    it 'sets the exclusion flag on the destination client when the checkbox param is present' do
      post clients_path, params: base_params.deep_merge(
        client: { exclude_from_external_data_sharing: '1' },
      )
      expect(ClientExternalDataSharing.new(created_destination).excluded?).to be true
      expect(GrdaWarehouse::ClientAttribute.where(client_id: created_source.id).count).to eq(0)
    end

    it 'does not create a ClientAttribute row when the checkbox param is absent' do
      post clients_path, params: base_params
      expect(GrdaWarehouse::ClientAttribute.where(client_id: created_destination.id).count).to eq(0)
    end
  end

  context 'when config is disabled' do
    before { stub_exclusion_config(false) }

    it 'does not create a ClientAttribute row even when the checkbox param is present' do
      post clients_path, params: base_params.deep_merge(
        client: { exclude_from_external_data_sharing: '1' },
      )
      expect(GrdaWarehouse::ClientAttribute.where(client_id: created_destination.id).count).to eq(0)
    end
  end

  context 'when user lacks can_create_clients permission' do
    before { sign_in create(:user) }

    it 'redirects and does not create a ClientAttribute row' do
      post clients_path, params: base_params.deep_merge(
        client: { exclude_from_external_data_sharing: '1' },
      )
      expect(response).to have_http_status(:redirect)
      expect(GrdaWarehouse::ClientAttribute.count).to eq(0)
    end
  end
end

RSpec.describe Clients::ExternalDataSharingController, type: :request do
  let(:source_ds) { create(:source_data_source) }
  let(:dest_ds)   { create(:destination_data_source) }
  let(:user)      { create(:user) }
  let(:source_client) { create(:hud_client, data_source: source_ds) }
  let!(:dest_client) do
    dest = GrdaWarehouse::Hud::Client.create!(
      source_client.attributes.except('id').merge('data_source_id' => dest_ds.id),
    )
    GrdaWarehouse::WarehouseClient.create!(
      id_in_source: source_client.PersonalID,
      data_source_id: source_client.data_source_id,
      source_id: source_client.id,
      destination_id: dest.id,
    )
    dest
  end

  before do
    user.legacy_roles << create(:can_edit_clients)
    sign_in user
  end

  def stub_enabled(value)
    allow(GrdaWarehouse::Config).to receive(:get).and_call_original
    allow(GrdaWarehouse::Config).to receive(:get).
      with(:enable_external_data_sharing_exclusion).
      and_return(value)
  end

  describe 'GET show' do
    context 'when feature is enabled' do
      before { stub_enabled(true) }

      it 'returns 200' do
        get client_external_data_sharing_path(dest_client)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when feature is disabled' do
      before { stub_enabled(false) }

      it 'redirects to the client page' do
        get client_external_data_sharing_path(dest_client)
        expect(response).to redirect_to(client_path(dest_client))
      end
    end
  end

  describe 'PATCH update' do
    context 'when feature is enabled' do
      before { stub_enabled(true) }

      it 'sets the exclusion flag to true' do
        patch client_external_data_sharing_path(dest_client),
              params: { exclude_from_external_data_sharing: '1' }
        expect(ClientExternalDataSharing.new(dest_client).excluded?).to be true
      end

      it 'sets the exclusion flag to false when param is absent' do
        ClientExternalDataSharing.new(dest_client).set_exclusion!(value: true)
        patch client_external_data_sharing_path(dest_client),
              params: { exclude_from_external_data_sharing: '0' }
        expect(ClientExternalDataSharing.new(dest_client).excluded?).to be false
      end

      it 'redirects to the client page' do
        patch client_external_data_sharing_path(dest_client),
              params: { exclude_from_external_data_sharing: '1' }
        expect(response).to redirect_to(client_path(dest_client))
      end
    end

    context 'when feature is disabled' do
      before { stub_enabled(false) }

      it 'does not change the exclusion flag' do
        patch client_external_data_sharing_path(dest_client),
              params: { exclude_from_external_data_sharing: '1' }
        expect(ClientExternalDataSharing.new(dest_client).excluded?).to be false
      end
    end
  end
end
