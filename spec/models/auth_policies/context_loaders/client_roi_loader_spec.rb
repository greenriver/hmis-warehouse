###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::ContextLoaders::ClientRoiLoader, type: :model do
  let(:user) { create(:user) }
  let(:loader) { described_class.new(user) }
  let(:client) { create(:warehouse_client) }
  let(:today) { Date.current }

  before do
    GrdaWarehouse::Config.delete_all
    create(:config_b)
    GrdaWarehouse::Config.invalidate_cache
  end

  describe '#get' do
    it 'returns false for client without ROI' do
      expect(loader.get(client.destination_id)).to be false
    end

    it 'returns true for client with active ROI and no CoC codes' do
      create(:client_roi_authorization, destination_client: client.destination, status: 'full', coc_codes: nil)

      expect(loader.get(client.destination_id)).to be true
    end

    it 'returns true when the ROI CoC matches a user CoC' do
      code = 'CO-500'
      create(:client_roi_authorization, destination_client: client.destination, status: 'full', coc_codes: [code])
      user.coc_codes = [code]

      expect(loader.get(client.destination_id)).to be true
    end

    it 'returns false when ROI coc_codes do not match user coc_codes' do
      # ROI restricted to a specific CoC; user has no CoC codes (no collections assigned)
      create(:client_roi_authorization, destination_client: client.destination, status: 'full', coc_codes: ['CO-500'])

      expect(loader.get(client.destination_id)).to be false
    end

    it 'returns true when ROI is All CoCs and user has specific coc_codes' do
      create(:client_roi_authorization, destination_client: client.destination, status: 'full', coc_codes: ['All CoCs'])
      user.coc_codes = ['PA-501']

      expect(loader.get(client.destination_id)).to be true
    end

    it 'returns false for a partial release under Consent::Default' do
      create(:client_roi_authorization, destination_client: client.destination, status: 'partial')
      expect(loader.get(client.destination_id)).to be false
    end

    it 'returns true for a partial (implied) authorization under Consent::Implied' do
      GrdaWarehouse::Config.delete_all
      create(:config_va)
      GrdaWarehouse::Config.invalidate_cache
      create(:client_roi_authorization, destination_client: client.destination, status: 'partial')
      expect(loader.get(client.destination_id)).to be true
    end

    it 'caches the result' do
      expect(GrdaWarehouse::ClientRoiAuthorization).to receive(:visible_in_cocs).once.and_call_original
      loader.get(client.destination_id)
      loader.get(client.destination_id)
    end
  end

  describe '#preload' do
    let(:client2) { create(:warehouse_client) }

    it 'loads multiple clients in one query' do
      expect(GrdaWarehouse::ClientRoiAuthorization).to receive(:visible_in_cocs).once.and_call_original
      loader.preload([client.destination_id, client2.destination_id])

      # Should not trigger more queries
      expect(GrdaWarehouse::ClientRoiAuthorization).not_to receive(:visible_in_cocs)
      loader.get(client.destination_id)
      loader.get(client2.destination_id)
    end
  end
end
