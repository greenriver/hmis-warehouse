# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Internal::CandidateRepository, type: :model do
  let!(:destination_data_source) { create :destination_data_source }
  let(:pool) { create(:hmis_ce_match_candidate_pool) }
  let!(:client1) { create(:hmis_hud_client, last_name: 'client1') }
  let!(:client2) { create(:hmis_hud_client, last_name: 'client2') }
  let(:destination_client1) { GrdaWarehouse::Hud::Client.find(client1.destination_client.id) }
  let(:destination_client2) { GrdaWarehouse::Hud::Client.find(client2.destination_client.id) }
  let(:repository) { described_class.new(pool) }
  let(:proxy) { create(:hmis_ce_client_proxy, client: destination_client1) }
  let(:new_proxy) { create(:hmis_ce_client_proxy, client: destination_client2) }

  before { GrdaWarehouse::Tasks::IdentifyDuplicates.new.run! }

  describe '#import_candidates' do
    let!(:existing_candidate) do
      create(:hmis_ce_match_candidate, candidate_pool: pool, client_proxy: proxy, priority_scores: [100])
    end

    context 'when a candidate with the same pool and proxy exists' do
      it 'updates the priority_score if it is different' do
        values = [
          {
            candidate_pool_id: pool.id,
            client_proxy_id: proxy.id,
            priority_scores: [200],
          },
        ]

        expect do
          repository.import_candidates(values)
        end.to change { existing_candidate.reload.priority_scores }.from([100]).to([200])
      end

      it 'does not update the priority_score if it is the same' do
        values = [
          {
            candidate_pool_id: pool.id,
            client_proxy_id: proxy.id,
            priority_scores: [100],
          },
        ]

        expect do
          repository.import_candidates(values)
        end.not_to(change { existing_candidate.reload.updated_at })
      end
    end

    context 'when importing a new candidate' do
      it 'creates a new candidate record' do
        values = [
          {
            candidate_pool_id: pool.id,
            client_proxy_id: new_proxy.id,
            priority_scores: [50],
          },
        ]

        expect do
          repository.import_candidates(values)
        end.to change { Hmis::Ce::Match::Candidate.count }.by(1)

        new_candidate = Hmis::Ce::Match::Candidate.last
        expect(new_candidate.priority_scores).to eq([50])
      end
    end
  end

  describe '#import_proxies' do
    it 'undeletes a soft-deleted proxy for a warehouse client' do
      # Ensure proxy exists then soft-delete it
      proxy # create for destination_client1
      expect(Hmis::Ce::ClientProxy.for_warehouse_clients.where(client_id: destination_client1.id)).to be_present
      proxy.destroy
      expect(Hmis::Ce::ClientProxy.for_warehouse_clients.where(client_id: destination_client1.id)).to be_empty

      # Import should undelete the proxy rather than creating a new one
      expect do
        repository.import_proxies([destination_client1], timestamp: Time.current)
      end.to change {
        Hmis::Ce::ClientProxy.for_warehouse_clients.where(client_id: destination_client1.id).count
      }.from(0).to(1)

      revived = Hmis::Ce::ClientProxy.find(proxy.id)
      expect(revived.deleted_at).to be_nil
    end

    it 'does not touch an active proxy (no updated_at change)' do
      proxy # create for destination_client1
      original_updated_at = proxy.updated_at

      repository.import_proxies([destination_client1], timestamp: Time.current)

      expect(proxy.reload.updated_at).to eq(original_updated_at)
    end

    it 'creates a new proxy when one does not exist' do
      expect(Hmis::Ce::ClientProxy.for_warehouse_clients.where(client_id: destination_client2.id)).to be_empty

      expect do
        repository.import_proxies([destination_client2], timestamp: Time.current)
      end.to change { Hmis::Ce::ClientProxy.for_warehouse_clients.where(client_id: destination_client2.id).count }.by(1)
    end
  end
end
