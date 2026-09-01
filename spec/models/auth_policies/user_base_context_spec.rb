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
end
