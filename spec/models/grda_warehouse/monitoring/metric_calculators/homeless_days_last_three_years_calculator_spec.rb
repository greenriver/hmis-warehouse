###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
