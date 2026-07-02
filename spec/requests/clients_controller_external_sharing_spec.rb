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
