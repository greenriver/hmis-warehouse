###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::ContextLoaders::RestrictedClientLoader, type: :model do
  let(:loader) { described_class.new }
  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:source_client) { create(:hmis_hud_client, data_source: hmis_ds) }
  let!(:destination_client) { create(:grda_warehouse_hud_client) }

  before do
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: source_client.id, data_source_id: hmis_ds.id, id_in_source: source_client.id.to_s)
  end

  describe '#restricted?' do
    it 'returns false for an unrestricted client' do
      expect(loader.restricted?(destination_client.id)).to eq(false)
    end

    it 'returns true for a restricted client' do
      source_client.mark_as_restricted!(user: hmis_user)
      expect(loader.restricted?(destination_client.id)).to eq(true)
    end

    it 'returns false for a nil id' do
      expect(loader.restricted?(nil)).to eq(false)
    end

    it 'caches the result' do
      source_client.mark_as_restricted!(user: hmis_user)
      expect(GrdaWarehouse::Hud::Client).to receive(:hmis_restricted_destination_client_ids).once.and_call_original
      loader.restricted?(destination_client.id)
      loader.restricted?(destination_client.id)
    end
  end

  describe '#preload' do
    let!(:destination_client2) { create(:grda_warehouse_hud_client) }
    let!(:source_client2) { create(:hmis_hud_client, data_source: hmis_ds) }

    before do
      GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client2.id, source_id: source_client2.id, data_source_id: hmis_ds.id, id_in_source: source_client2.id.to_s)
      source_client2.mark_as_restricted!(user: hmis_user)
    end

    it 'loads multiple clients in one query and warms the cache for both' do
      expect(GrdaWarehouse::Hud::Client).to receive(:hmis_restricted_destination_client_ids).once.and_call_original
      loader.preload([destination_client.id, destination_client2.id])

      expect(GrdaWarehouse::Hud::Client).not_to receive(:hmis_restricted_destination_client_ids)
      expect(loader.restricted?(destination_client.id)).to eq(false)
      expect(loader.restricted?(destination_client2.id)).to eq(true)
    end
  end
end
