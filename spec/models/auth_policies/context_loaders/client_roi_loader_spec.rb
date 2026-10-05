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

    it 'returns false when the only source client is in a data source that does not obey consent' do
      client.source.data_source.update!(obey_consent: false)
      create(:client_roi_authorization, destination_client: client.destination, status: 'full')

      expect(loader.get(client.destination_id)).to be false
    end

    it 'caches the result' do
      create(:client_roi_authorization, destination_client: client.destination, status: 'full')
      expect(roi_queries { loader.get(client.destination_id) }).to eq(1)
      expect(roi_queries { expect(loader.get(client.destination_id)).to be true }).to eq(0)
    end
  end

  describe '#full_release?' do
    it 'returns true for a full release' do
      create(:client_roi_authorization, destination_client: client.destination, status: 'full')
      expect(loader.full_release?(client.destination_id)).to be true
    end

    it 'returns false for a client without ROI' do
      expect(loader.full_release?(client.destination_id)).to be false
    end

    it 'returns false for a partial (implied) authorization under Consent::Implied, where get returns true' do
      GrdaWarehouse::Config.delete_all
      create(:config_va)
      GrdaWarehouse::Config.invalidate_cache
      create(:client_roi_authorization, destination_client: client.destination, status: 'partial')

      expect(loader.get(client.destination_id)).to be true
      expect(loader.full_release?(client.destination_id)).to be false
    end

    it 'returns false when the full release is limited to a CoC the user lacks' do
      create(:client_roi_authorization, destination_client: client.destination, status: 'full', coc_codes: ['CO-500'])
      expect(loader.full_release?(client.destination_id)).to be false
    end

    it 'returns false when the only source client is in a data source that does not obey consent' do
      client.source.data_source.update!(obey_consent: false)
      create(:client_roi_authorization, destination_client: client.destination, status: 'full')
      expect(loader.full_release?(client.destination_id)).to be false
    end

    it 'answers from the cache after get, without another query' do
      create(:client_roi_authorization, destination_client: client.destination, status: 'full')
      loader.get(client.destination_id)
      expect(roi_queries { expect(loader.full_release?(client.destination_id)).to be true }).to eq(0)
    end

    it 'counts an unpreloaded lookup as a miss' do
      tracker = GrdaWarehouse::AuthPolicies::PreloadMissTracker.new
      tracked_loader = described_class.new(user, miss_tracker: tracker)
      ids = create_list(:warehouse_client, 4).map(&:destination_id)

      expect { ids.each { |id| tracked_loader.full_release?(id) } }.
        to raise_error(GrdaWarehouse::AuthPolicies::PreloadMissTracker::PreloadMissError, /client_roi/)
    end
  end

  describe '#preload' do
    let(:client2) { create(:warehouse_client) }

    it 'loads multiple clients in one query and caches each result' do
      create(:client_roi_authorization, destination_client: client.destination, status: 'full')
      expect(roi_queries { loader.preload([client.destination_id, client2.destination_id]) }).to eq(1)

      results = nil
      queries = roi_queries { results = [loader.get(client.destination_id), loader.get(client2.destination_id)] }
      expect(queries).to eq(0)
      expect(results).to eq([true, false])
    end
    it 'preloads full_release? for every client in one query' do
      create(:client_roi_authorization, destination_client: client.destination, status: 'full')
      create(:client_roi_authorization, destination_client: client2.destination, status: 'partial')
      expect(roi_queries { loader.preload([client.destination_id, client2.destination_id]) }).to eq(1)

      results = nil
      queries = roi_queries { results = [client.destination_id, client2.destination_id].map { |id| loader.full_release?(id) } }
      expect(queries).to eq(0)
      expect(results).to eq([true, false])
    end
  end

  describe 'miss tracking' do
    let(:tracker) { GrdaWarehouse::AuthPolicies::PreloadMissTracker.new }
    let(:tracked_loader) { described_class.new(user, miss_tracker: tracker) }
    let(:destination_ids) { create_list(:warehouse_client, 4).map(&:destination_id) }

    it 'raises once more clients than the threshold are checked without a preload' do
      expect { destination_ids.each { |id| tracked_loader.get(id) } }.
        to raise_error(GrdaWarehouse::AuthPolicies::PreloadMissTracker::PreloadMissError, /client_roi/)
    end

    it 'does not count preloaded clients as misses' do
      tracked_loader.preload(destination_ids)

      expect(destination_ids.map { |id| tracked_loader.get(id) }).to eq([false] * 4)
    end
  end

  def roi_queries(&block)
    count = 0
    counter = ->(*, payload) { count += 1 if payload[:sql].include?('client_roi_authorizations') }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &block)
    count
  end
end
