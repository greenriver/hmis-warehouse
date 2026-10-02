###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::UserBaseContext do
  let(:user) { create(:user) }
  let(:context) { described_class.new(user) }
  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:source_client) { create(:hmis_hud_client, data_source: hmis_ds) }
  let!(:destination_client) { create(:grda_warehouse_hud_client) }

  before do
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: source_client.id, data_source_id: hmis_ds.id, id_in_source: source_client.id.to_s)
  end

  describe '#client_restricted?' do
    it 'returns false for an unrestricted client' do
      expect(context.client_restricted?(destination_client.id)).to eq(false)
    end

    it 'returns true once the client is restricted, checking by destination id' do
      source_client.mark_as_restricted!(user: hmis_user)
      expect(context.client_restricted?(destination_client.id)).to eq(true)
    end

    it 'returns true once the client is restricted, checking by source id' do
      source_client.mark_as_restricted!(user: hmis_user)
      expect(context.client_restricted?(source_client.id)).to eq(true)
    end

    it 'returns false for a nil id' do
      expect(context.client_restricted?(nil)).to eq(false)
    end
  end

  describe '#client_restriction_cache_token' do
    let!(:other_client) { create(:grda_warehouse_hud_client) }

    # Answers are memoized per context, so each "after" reading needs a fresh one.
    def token_for(client_id)
      described_class.new(user).client_restriction_cache_token(client_id)
    end

    it 'changes for a client when that client is restricted' do
      before = token_for(destination_client.id)
      source_client.mark_as_restricted!(user: hmis_user)

      expect(token_for(destination_client.id)).not_to eq(before)
    end

    it 'does not change for an unrelated client when another client is restricted' do
      before = token_for(other_client.id)
      source_client.mark_as_restricted!(user: hmis_user)

      expect(token_for(other_client.id)).to eq(before)
    end

    it 'changes once a retention run completes' do
      before = token_for(other_client.id)
      GrdaWarehouse::ClientRetentionRun.create!(started_at: 1.minute.ago, completed_at: Time.current, global_retention_years: 7)

      expect(token_for(other_client.id)).not_to eq(before)
    end
  end
end
