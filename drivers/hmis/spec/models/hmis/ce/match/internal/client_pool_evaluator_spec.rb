# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Internal::ClientPoolEvaluator, type: :model do
  let!(:destination_data_source) { create :destination_data_source }
  let(:current_date) { Date.new(2024, 12, 26) }
  let(:field_map) { Hmis::Ce::Match::Expression::FieldMap.new(current_date: current_date) }
  let(:pool) do
    create(
      :hmis_ce_match_candidate_pool,
      requirement_expression: 'current_age > 65 AND veteran_status = 1',
      priority_expression: 'current_age',
    )
  end

  # Create clients with varying attributes to test against the pool's expressions
  let!(:client_vet_young) { create(:hmis_hud_client_with_warehouse_client, dob: 25.years.ago(current_date), veteran_status: 1) } # age 25, vet
  let!(:destination_client1) { client_vet_young.destination_client }

  let!(:client_non_vet_old) { create(:hmis_hud_client_with_warehouse_client, dob: 70.years.ago(current_date), veteran_status: 0) } # age 70, not vet
  let!(:destination_client2) { client_non_vet_old.destination_client }

  let!(:client_vet_old) { create(:hmis_hud_client_with_warehouse_client, dob: 68.years.ago(current_date), veteran_status: 1) } # age 68, vet
  let!(:destination_client3) { client_vet_old.destination_client }

  let(:clients) { GrdaWarehouse::Hud::Client.where(id: [destination_client1.id, destination_client2.id, destination_client3.id]) }
  let(:evaluator) { described_class.new(clients, pool, field_map) }

  describe '#call' do
    context 'when a client meets the pool requirements' do
      it 'returns a successful result with the correct priority score' do
        result = evaluator.call(destination_client3) # age 68, vet -> should pass

        expect(result).not_to be_failed
        expect(result.priority_score).to eq(68)
        expect(result.client_values).to include(
          'current_age' => 68,
          'veteran_status' => 1,
        )
      end
    end

    context 'when a client does not meet the pool requirements' do
      it 'returns a failed result for a client that is too young' do
        result = evaluator.call(destination_client1) # age 25 -> fails age check

        expect(result).to be_failed
        expect(result.priority_score).to be_nil
      end

      it 'returns a failed result for a client that is not a veteran' do
        result = evaluator.call(destination_client2) # not vet -> fails vet status check

        expect(result).to be_failed
        expect(result.priority_score).to be_nil
      end
    end

    describe 'batch loading behavior' do
      # This test inspects the internal state of the evaluator to confirm that
      # it correctly pre-fetches and caches the required data for all clients in the batch.
      # This is the core responsibility of this class.
      it 'pre-loads all dependency values for all clients upon initialization' do
        client_field_values = evaluator.instance_variable_get(:@client_field_values)

        expect(client_field_values.keys).to contain_exactly(destination_client1.id, destination_client2.id, destination_client3.id)

        expect(client_field_values[destination_client1.id]).to eq('current_age' => 25, 'veteran_status' => 1)
        expect(client_field_values[destination_client2.id]).to eq('current_age' => 70, 'veteran_status' => 0)
        expect(client_field_values[destination_client3.id]).to eq('current_age' => 68, 'veteran_status' => 1)
      end

      # To verify that the evaluator avoids N+1 queries, we spy on the field_map.
      # This ensures that the data is fetched once for the entire batch, not once per client.
      it 'queries the field map only once per dependency for the entire batch' do
        field_map_spy = spy(field_map)
        # Re-initialize the evaluator with the spy to track calls
        described_class.new(clients, pool, field_map_spy)

        expect(field_map_spy).to have_received(:client_query).with(clients, 'current_age').once
        expect(field_map_spy).to have_received(:client_query).with(clients, 'veteran_status').once
      end
    end
  end
end
