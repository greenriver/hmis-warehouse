###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::ClientProxy, type: :model do
  let!(:destination_client) { create :grda_warehouse_hud_client }
  let!(:source_client) { create :hmis_hud_client }

  describe 'ClientProxy model validations' do
    it 'expects a destination client' do
      proxy = build(:hmis_ce_client_proxy, client: destination_client)
      expect(proxy.valid?).to be_truthy
      expect do
        proxy.save!
      end.to change(Hmis::Ce::ClientProxy, :count).from(0).to(1)
    end

    it 'raises for source client' do
      proxy = build(:hmis_ce_client_proxy, client: source_client)
      expect(proxy.valid?).to be_falsy
      expect do
        proxy.save!
      end.to raise_error(ActiveRecord::RecordInvalid, /must be destination client/)
    end
  end

  describe 'Client deletion behavior' do
    let!(:proxy) { create(:hmis_ce_client_proxy, client: destination_client) }
    let!(:candidate) { create(:hmis_ce_match_candidate, client_proxy: proxy) }

    it 'deletes associated proxies and candidates' do
      expect do
        destination_client.destroy!
      end.to change(Hmis::Ce::Match::Candidate, :count).by(-1).
        and change(Hmis::Ce::ClientProxy, :count).by(-1)

      expect(Hmis::Ce::ClientProxy.find_by(id: proxy.id)).to be_nil
      expect(Hmis::Ce::Match::Candidate.find_by(id: candidate.id)).to be_nil
    end
  end

  describe 'join_latest_event_per_candidate_pool scope' do
    let!(:client_proxy_1) { create(:hmis_ce_client_proxy) }
    let!(:client_proxy_2) { create(:hmis_ce_client_proxy) } # needs candidates

    let!(:candidate_pool_1) { create(:hmis_ce_match_candidate_pool_with_candidates, client_proxies: [client_proxy_1]) }
    let!(:candidate_pool_2) { create(:hmis_ce_match_candidate_pool_with_candidates, client_proxies: [client_proxy_1, client_proxy_2]) }

    # Client 1 updated in Pool 1
    let!(:event_client1_pool1_1) { create(:hmis_ce_match_candidate_event, client_proxy: client_proxy_1, candidate_pool: candidate_pool_1, created_at: 1.day.ago, event_name: 'update', snapshot: { 'foo' => 'most recent', 'numeric_score' => 3 }) }
    # Client 1 added to Pool 1
    let!(:event_client1_pool1_2) { create(:hmis_ce_match_candidate_event, client_proxy: client_proxy_1, candidate_pool: candidate_pool_1, created_at: 2.days.ago, event_name: 'add', snapshot: { 'foo' => 'older' }) }
    # Client 1 added to Pool 2
    let!(:event_client1_pool2_1) { create(:hmis_ce_match_candidate_event, client_proxy: client_proxy_1, candidate_pool: candidate_pool_2, created_at: 3.days.ago, event_name: 'add', snapshot: { 'foo' => 'most recent for pool 2', 'bar' => 'most recent for pool 2' }) }
    # Client 2 added to Pool 2
    let!(:event_client2_pool2_1) { create(:hmis_ce_match_candidate_event, client_proxy: client_proxy_2, candidate_pool: candidate_pool_2, created_at: 2.days.ago, event_name: 'add', snapshot: { 'foo' => 'most recent for client 2', 'project_types' => [1, 2, 3] }) }
    # Client 2 removed from to Pool 1
    let!(:event_client2_pool1_1) { create(:hmis_ce_match_candidate_event, client_proxy: client_proxy_2, candidate_pool: candidate_pool_1, created_at: 1.day.ago, event_name: 'remove', snapshot: { 'foo' => 'most recent event but does not belong to pool' }) }

    it 'returns client proxies with the latest event per candidate pool' do
      result = described_class.join_latest_event_per_candidate_pool
      expect(result).to contain_exactly(
        have_attributes(id: client_proxy_1.id, candidate_pool_id: candidate_pool_1.id, latest_snapshot_for_candidate_pool: event_client1_pool1_1.snapshot),
        have_attributes(id: client_proxy_1.id, candidate_pool_id: candidate_pool_2.id, latest_snapshot_for_candidate_pool: event_client1_pool2_1.snapshot),
        have_attributes(id: client_proxy_2.id, candidate_pool_id: candidate_pool_2.id, latest_snapshot_for_candidate_pool: event_client2_pool2_1.snapshot),
      )

      snapshots = result.map(&:latest_snapshot_for_candidate_pool)
      expect(snapshots).not_to include(event_client1_pool1_2) # Excluded because it is not the most recent event for Client 1 : Pool 1
      expect(snapshots).not_to include(event_client2_pool1_1) # Excluded because client 2 no longer belongs to this pool
    end

    describe '#filter_by_attribute' do
      it 'returns matching client' do
        result = described_class.join_latest_event_per_candidate_pool.filter_by_attribute(key: 'foo', values: ['most recent'])
        expect(result).to contain_exactly(client_proxy_1)
      end
      it 'returns matching client for attribute if matches most recent event for any pool' do
        result = described_class.join_latest_event_per_candidate_pool.filter_by_attribute(key: 'foo', values: ['most recent for pool 2'])
        expect(result).to contain_exactly(client_proxy_1)
      end
      it 'returns matching clients when multiple values are passed (OR)' do
        result = described_class.join_latest_event_per_candidate_pool.filter_by_attribute(key: 'foo', values: ['most recent', 'most recent for client 2', 'another term without match'])
        expect(result).to contain_exactly(client_proxy_1, client_proxy_2)
      end
      it 'excludes client that matches a historical event but not the most recent' do
        result = described_class.join_latest_event_per_candidate_pool.filter_by_attribute(key: 'foo', values: ['older'])
        expect(result).to be_empty
      end
      it 'returns matching clients when filtering on numeric array attribute (ANY)' do
        result = described_class.join_latest_event_per_candidate_pool.filter_by_attribute(key: 'project_types', values: [1, 2])
        expect(result).to contain_exactly(client_proxy_2)
      end
      it 'returns matching clients when filtering on numeric array attribute when values are stringified' do
        result = described_class.join_latest_event_per_candidate_pool.filter_by_attribute(key: 'project_types', values: ['1', '2'])
        expect(result).to contain_exactly(client_proxy_2)
      end
      it 'returns matching clients when filtering on numeric attribute' do
        result = described_class.join_latest_event_per_candidate_pool.filter_by_attribute(key: 'numeric_score', values: [3])
        expect(result).to contain_exactly(client_proxy_1)
      end
      it 'returns matching clients when filtering on numeric attribute when value is stringified' do
        result = described_class.join_latest_event_per_candidate_pool.filter_by_attribute(key: 'numeric_score', values: ['3'])
        expect(result).to contain_exactly(client_proxy_1)
      end
      it 'returns empty when filtering on array attribute (ANY) and none match' do
        result = described_class.join_latest_event_per_candidate_pool.filter_by_attribute(key: 'project_types', values: ['6'])
        expect(result).to be_empty
      end
    end
  end
end
