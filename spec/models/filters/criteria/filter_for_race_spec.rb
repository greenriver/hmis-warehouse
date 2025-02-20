
require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForRace do
  include_context 'filter criteria setup'

  let(:races) { ['White', 'BlackAfAmerican'] }

  # Create clients with different races
  let!(:white_client) { create(:hud_client, White: 1, BlackAfAmerican: 0, Asian: 0, AmIndAKNative: 0, NativeHIPacific: 0, MidEastNAfrican: 0, data_source_id: data_source.id) }
  let!(:black_client) { create(:hud_client, White: 0, BlackAfAmerican: 1, Asian: 0, AmIndAKNative: 0, NativeHIPacific: 0, MidEastNAfrican: 0, data_source_id: data_source.id) }
  let!(:asian_client) { create(:hud_client, White: 0, BlackAfAmerican: 0, Asian: 1, AmIndAKNative: 0, NativeHIPacific: 0, MidEastNAfrican: 0, data_source_id: data_source.id) }
  let!(:multi_racial_client) { create(:hud_client, White: 0, BlackAfAmerican: 0, Asian: 1, AmIndAKNative: 0, NativeHIPacific: 1, MidEastNAfrican: 1, data_source_id: data_source.id) }

  # Create service history enrollments for each client
  let!(:enrollments) do
    [white_client, black_client, asian_client, multi_racial_client].map do |client|
      create_enrollment_for_client(client)
    end
  end

  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      start: start_date,
      end: end_date,
      races: races
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
      expect(result.pluck(:client_id)).not_to include(asian_client.id)
    end

    context 'when filtering for MultiRacial' do
      let(:races) { ['MultiRacial'] }

      it 'filters for clients with multiple races' do
        result = criteria.apply(scope)

        # Should return only the multi-racial client
        expect(result.count).to eq(1)
        expect(result.pluck(:client_id)).to contain_exactly(multi_racial_client.id)
      end
    end

    context 'when filtering for both specific races and MultiRacial' do
      let(:races) { ['Asian', 'MultiRacial'] }

      it 'returns clients matching either criteria' do
        result = criteria.apply(scope)

        # Should return white client and multi-racial client
        expect(result.count).to eq(1)
        expect(result.pluck(:client_id)).to contain_exactly(multi_racial_client.id)
      end
    end
  end
end
