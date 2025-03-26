# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForRace do
  include_context 'filter criteria setup'

  let(:races) { ['White', 'BlackAfAmerican'] }

  # Create clients with different races
  let!(:white_client) { create(:hud_client, White: 1, BlackAfAmerican: 0, Asian: 0, AmIndAKNative: 0, NativeHIPacific: 0, MidEastNAfrican: 0, data_source_id: data_source.id) }
  let!(:black_client) { create(:hud_client, White: 0, BlackAfAmerican: 1, Asian: 0, AmIndAKNative: 0, NativeHIPacific: 0, MidEastNAfrican: 0, data_source_id: data_source.id) }
  let!(:asian_client) { create(:hud_client, White: 0, BlackAfAmerican: 0, Asian: 1, AmIndAKNative: 0, NativeHIPacific: 0, MidEastNAfrican: 0, data_source_id: data_source.id) }
  let!(:asian_multi_racial_client) { create(:hud_client, White: 0, BlackAfAmerican: 0, Asian: 1, AmIndAKNative: 0, NativeHIPacific: 1, MidEastNAfrican: 1, data_source_id: data_source.id) }
  let!(:non_asian_multi_racial_client) { create(:hud_client, White: 0, BlackAfAmerican: 0, Asian: 0, AmIndAKNative: 0, NativeHIPacific: 1, MidEastNAfrican: 1, data_source_id: data_source.id) }

  # Client with RaceNone=1 (all race fields=0)
  let!(:race_none_client) { create(:hud_client, White: 0, BlackAfAmerican: 0, Asian: 0, AmIndAKNative: 0, NativeHIPacific: 0, MidEastNAfrican: 0, RaceNone: 1, data_source_id: data_source.id) }

  # Clients with different data quality issues
  let!(:client_doesnt_know) { create(:hud_client, White: 0, BlackAfAmerican: 0, Asian: 0, AmIndAKNative: 0, NativeHIPacific: 0, MidEastNAfrican: 0, RaceNone: 8, data_source_id: data_source.id) }
  let!(:client_refused) { create(:hud_client, White: 0, BlackAfAmerican: 0, Asian: 0, AmIndAKNative: 0, NativeHIPacific: 0, MidEastNAfrican: 0, RaceNone: 9, data_source_id: data_source.id) }
  let!(:data_not_collected) { create(:hud_client, White: 0, BlackAfAmerican: 0, Asian: 0, AmIndAKNative: 0, NativeHIPacific: 0, MidEastNAfrican: 0, RaceNone: 99, data_source_id: data_source.id) }
  let!(:all_race_null_client) { create(:hud_client, White: nil, BlackAfAmerican: nil, Asian: nil, AmIndAKNative: nil, NativeHIPacific: nil, MidEastNAfrican: nil, RaceNone: nil, data_source_id: data_source.id) }

  # Create service history enrollments for each client
  let!(:enrollments) do
    [white_client, black_client, asian_client, asian_multi_racial_client, non_asian_multi_racial_client, race_none_client, client_doesnt_know, client_refused, data_not_collected, all_race_null_client].map do |client|
      create_enrollment_for_client(client)
    end
  end

  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      start: start_date,
      end: end_date,
      races: races,
    )
  end

  let(:criteria) { described_class.new(input: filter, config: config) }

  it_behaves_like 'a criteria that applies conditionally', :races, ['White', 'BlackAfAmerican']

  describe '#apply' do
    it 'filters by the selected races' do
      result = criteria.apply(scope)

      # Should return white and black clients only
      expect(result.count).to eq(2)
      expect(result.pluck(:client_id)).to contain_exactly(white_client.id, black_client.id)
    end

    context 'when filtering for MultiRacial' do
      let(:races) { ['MultiRacial'] }

      it 'filters for clients with multiple races' do
        result = criteria.apply(scope)

        # Should return only the multi-racial clients
        expect(result.count).to eq(2)
        expect(result.pluck(:client_id)).to contain_exactly(
          asian_multi_racial_client.id,
          non_asian_multi_racial_client.id,
        )
      end
    end

    context 'when filtering for both specific races and MultiRacial' do
      let(:races) { ['Asian', 'MultiRacial'] }

      it 'returns clients matching either criteria' do
        result = criteria.apply(scope)

        expect(result.count).to eq(1)
        expect(result.pluck(:client_id)).to contain_exactly(asian_multi_racial_client.id)
      end
    end

    context 'when filtering for RaceNone' do
      let(:races) { ['RaceNone'] }

      it 'returns clients with RaceNone=1 and clients with race data quality issues' do
        result = criteria.apply(scope)

        # Should return race_none client and all clients with data quality issues
        expect(result.count).to eq(5)
        expect(result.pluck(:client_id)).to contain_exactly(
          race_none_client.id,
          client_doesnt_know.id,
          client_refused.id,
          data_not_collected.id,
          all_race_null_client.id,
        )
      end
    end

    context 'when all races are selected' do
      let(:races) { ['AmIndAKNative', 'Asian', 'BlackAfAmerican', 'MidEastNAfrican', 'NativeHIPacific', 'White', 'RaceNone'] }

      it 'returns all clients' do
        result = criteria.apply(scope)

        # Should return all clients
        expect(result.count).to eq(10)
        expect(result.pluck(:client_id)).to contain_exactly(
          white_client.id,
          black_client.id,
          asian_client.id,
          asian_multi_racial_client.id,
          non_asian_multi_racial_client.id,
          race_none_client.id,
          client_doesnt_know.id,
          client_refused.id,
          data_not_collected.id,
          all_race_null_client.id,
        )
      end
    end
  end
end
