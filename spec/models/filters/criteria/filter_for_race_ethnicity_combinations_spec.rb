# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForRaceEthnicityCombinations do
  include_context 'filter criteria setup'

  let(:race_ethnicity_combinations) { ['white', 'asian_hispanic_latinaeo'] }

  # Create clients with different race/ethnicity combinations
  let!(:white_non_hispanic) do
    create(:hud_client,
           White: 1,
           BlackAfAmerican: 0,
           Asian: 0,
           AmIndAKNative: 0,
           NativeHIPacific: 0,
           MidEastNAfrican: 0,
           HispanicLatinaeo: 0,
           data_source_id: data_source.id)
  end

  let!(:asian_hispanic) do
    create(:hud_client,
           White: 0,
           BlackAfAmerican: 0,
           Asian: 1,
           AmIndAKNative: 0,
           NativeHIPacific: 0,
           MidEastNAfrican: 0,
           HispanicLatinaeo: 1,
           data_source_id: data_source.id)
  end

  let!(:asian_non_hispanic) do
    create(:hud_client,
           White: 0,
           BlackAfAmerican: 0,
           Asian: 1,
           AmIndAKNative: 0,
           NativeHIPacific: 0,
           MidEastNAfrican: 0,
           HispanicLatinaeo: 0,
           data_source_id: data_source.id)
  end

  let!(:multi_racial_hispanic) do
    create(:hud_client,
           White: 1,
           BlackAfAmerican: 1,
           Asian: 0,
           AmIndAKNative: 0,
           NativeHIPacific: 0,
           MidEastNAfrican: 0,
           HispanicLatinaeo: 1,
           data_source_id: data_source.id)
  end

  # Create enrollments for each client
  let!(:enrollments) do
    [white_non_hispanic, asian_hispanic, asian_non_hispanic, multi_racial_hispanic].map do |client|
      create_enrollment_for_client(client)
    end
  end

  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      start: start_date,
      end: end_date,
      race_ethnicity_combinations: race_ethnicity_combinations,
    )
  end

  let(:criteria) { described_class.new(input: filter, config: config) }

  it_behaves_like 'a criteria that applies conditionally', :race_ethnicity_combinations, ['white', 'asian_hispanic_latinaeo']

  describe '#apply' do
    it 'filters by the selected race/ethnicity combinations' do
      result = criteria.apply(scope)

      # Should return white non-hispanic and asian hispanic clients
      expect(result.count).to eq(2)
      expect(result.pluck(:client_id)).to contain_exactly(white_non_hispanic.id, asian_hispanic.id)
      expect(result.pluck(:client_id)).not_to include(asian_non_hispanic.id)
    end

    context 'with multi-racial hispanic selection' do
      let(:race_ethnicity_combinations) { ['multi_racial_hispanic_latinaeo'] }

      it 'filters for multi-racial hispanic clients' do
        result = criteria.apply(scope)

        expect(result.count).to eq(1)
        expect(result.pluck(:client_id)).to contain_exactly(multi_racial_hispanic.id)
      end
    end

    context 'when filtering for race without hispanic specification' do
      let(:race_ethnicity_combinations) { ['asian'] }

      it 'returns non hispanic asian clients' do
        result = criteria.apply(scope)

        expect(result.count).to eq(1)
        expect(result.pluck(:client_id)).to contain_exactly(asian_non_hispanic.id)
      end
    end
    context 'when filtering for race with hispanic specification' do
      let(:race_ethnicity_combinations) { ['asian_hispanic_latinaeo'] }

      it 'returns clients matching both race and hispanic' do
        result = criteria.apply(scope)

        expect(result.count).to eq(1)
        expect(result.pluck(:client_id)).to contain_exactly(asian_hispanic.id)
      end
    end

    context 'when filtering for multiple combinations' do
      let(:race_ethnicity_combinations) { ['white', 'multi_racial_hispanic_latinaeo'] }

      it 'returns clients matching any of the specified combinations' do
        result = criteria.apply(scope)

        # Should return white non-hispanic and multi-racial hispanic clients
        expect(result.count).to eq(2)
        expect(result.pluck(:client_id)).to contain_exactly(white_non_hispanic.id, multi_racial_hispanic.id)
      end
    end

    context 'with no race specified' do
      let(:race_ethnicity_combinations) { ['race_none'] }
      let!(:no_race_client) do
        create(:hud_client,
               White: 0,
               BlackAfAmerican: 0,
               Asian: 0,
               AmIndAKNative: 0,
               NativeHIPacific: 0,
               MidEastNAfrican: 0,
               RaceNone: 8,
               data_source_id: data_source.id)
      end
      let!(:no_race_enrollment) { create_enrollment_for_client(no_race_client) }

      it 'returns clients with no race specified' do
        result = criteria.apply(scope)

        expect(result.count).to eq(1)
        expect(result.pluck(:client_id)).to contain_exactly(no_race_client.id)
      end
    end
  end
end
