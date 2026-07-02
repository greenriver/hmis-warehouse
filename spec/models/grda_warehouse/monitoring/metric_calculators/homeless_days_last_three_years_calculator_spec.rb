###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator, type: :model do
  let(:calculation_date) { Date.current }
  let(:client) { create(:grda_warehouse_hud_client) }
  let(:calculator) { described_class.new(client, calculation_date) }

  describe '#calculate' do
    context 'when client has no processed record' do
      it 'returns nil' do
        expect(calculator.calculate).to be_nil
      end
    end

    context 'when client has processed record' do
      let!(:processed) do
        create(
          :grda_warehouse_warehouse_clients_processed,
          client_id: client.id,
          routine: 'service_history',
          days_homeless_last_three_years: 365,
        )
      end

      it 'returns days_homeless_last_three_years' do
        expect(calculator.calculate).to eq(365)
      end
    end

    context 'when client has zero homeless days' do
      let!(:processed) do
        create(
          :grda_warehouse_warehouse_clients_processed,
          client_id: client.id,
          routine: 'service_history',
          days_homeless_last_three_years: 0,
        )
      end

      it 'returns zero' do
        expect(calculator.calculate).to eq(0)
      end
    end
  end

  describe '.calculate_batch' do
    let!(:client1) { create(:grda_warehouse_hud_client) }
    let!(:client2) { create(:grda_warehouse_hud_client) }
    let!(:client3) { create(:grda_warehouse_hud_client) }
    let(:entities) { [client1, client2, client3] }

    context 'when some clients have processed records' do
      let!(:processed1) do
        create(
          :grda_warehouse_warehouse_clients_processed,
          client_id: client1.id,
          routine: 'service_history',
          days_homeless_last_three_years: 100,
        )
      end

      let!(:processed3) do
        create(
          :grda_warehouse_warehouse_clients_processed,
          client_id: client3.id,
          routine: 'service_history',
          days_homeless_last_three_years: 200,
        )
      end

      it 'returns hash with only clients that have data' do
        result = described_class.calculate_batch(entities, calculation_date)

        expect(result).to be_a(Hash)
        expect(result[client1.id]).to eq(100)
        expect(result[client2.id]).to be_nil
        expect(result[client3.id]).to eq(200)
      end

      it 'uses a single query' do
        # Force entity creation before counting queries
        entities

        expect do
          described_class.calculate_batch(entities, calculation_date)
        end.to make_database_queries(count: 1)
      end
    end

    context 'when no clients have processed records' do
      it 'returns empty hash' do
        result = described_class.calculate_batch(entities, calculation_date)

        expect(result).to eq({})
      end
    end
  end

  describe '.change_metrics' do
    let(:snapshot) do
      Struct.new(:initial_value, :current_value, :current_observation_date, keyword_init: true).new(
        initial_value: 100,
        current_value: 130,
        current_observation_date: Date.current - 1,
      )
    end

    it 'measures change from the previous run value, not the original baseline' do
      result = described_class.change_metrics(
        previous_snapshot: snapshot,
        calculated_value: 131,
        calculation_date: Date.current,
      )

      # 131 - 130 (current_value / previous run), NOT 131 - 100 (initial_value)
      expect(result[:count_change]).to eq(1)
    end

    it 'normalizes count and percent to a per-day rate across elapsed days' do
      snapshot.current_observation_date = Date.current - 10

      result = described_class.change_metrics(
        previous_snapshot: snapshot,
        calculated_value: 175, # +45 over a 10-day gap
        calculation_date: Date.current,
      )

      expect(result[:count_change]).to eq(4.5) # 45 / 10 days
      # percent aligns with the per-day count: (45 / 10) as a percent of the previous value
      expect(result[:percent_change]).to be_within(0.001).of(4.5 / 130 * 100)
    end

    it 'treats a zero or negative day gap as a single day' do
      snapshot.current_observation_date = Date.current

      result = described_class.change_metrics(
        previous_snapshot: snapshot,
        calculated_value: 160, # +30 vs current 130
        calculation_date: Date.current,
      )

      expect(result[:count_change]).to eq(30) # divided by 1, not 0
    end
  end

  describe '.metric_definition_attributes' do
    let(:attrs) { described_class.metric_definition_attributes }

    it 'returns hash with required attributes' do
      expect(attrs).to include(
        name: 'days_homeless_last_three_years',
        entity_type: 'GrdaWarehouse::Hud::Client',
        calculator_class: described_class.name,
        count_change_threshold: 30,
      )
    end

    it 'includes display name and description' do
      expect(attrs[:display_name]).to be_present
      expect(attrs[:description]).to be_present
    end
  end
end
