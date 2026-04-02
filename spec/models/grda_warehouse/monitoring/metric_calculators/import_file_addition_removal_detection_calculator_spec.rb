# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Monitoring::MetricCalculators::ImportFileAdditionRemovalDetectionCalculator do
  let(:data_source) { create(:grda_warehouse_data_source) }

  describe '.exceeded?' do
    context 'with min_additions_threshold' do
      let(:monitor) do
        create(:grda_warehouse_import_csv_monitor,
               data_source: data_source,
               csv_file_name: 'Services.csv',
               min_additions_threshold: 500,
               count_increase_threshold: nil,
               count_decrease_threshold: nil)
      end

      it 'returns hash when added is below threshold' do
        current = { pre_processed: 1000, added: 200, removed: 0 }
        result = described_class.exceeded?(monitor: monitor, current: current)
        expect(result).to eq(reason: :min_additions, added: 200, threshold: 500)
      end

      it 'returns false when added meets threshold' do
        current = { pre_processed: 1000, added: 500, removed: 0 }
        expect(described_class.exceeded?(monitor: monitor, current: current)).to be false
      end

      it 'returns false when added exceeds threshold' do
        current = { pre_processed: 1000, added: 600, removed: 0 }
        expect(described_class.exceeded?(monitor: monitor, current: current)).to be false
      end
    end

    context 'with max_removals_threshold' do
      let(:monitor) do
        create(:grda_warehouse_import_csv_monitor,
               data_source: data_source,
               csv_file_name: 'Enrollment.csv',
               max_removals_threshold: 100,
               count_increase_threshold: nil,
               count_decrease_threshold: nil)
      end

      it 'returns hash when removed exceeds threshold' do
        current = { pre_processed: 900, added: 0, removed: 150 }
        result = described_class.exceeded?(monitor: monitor, current: current)
        expect(result).to eq(reason: :max_removals, removed: 150, threshold: 100)
      end

      it 'returns false when removed is at threshold' do
        current = { pre_processed: 900, added: 0, removed: 100 }
        expect(described_class.exceeded?(monitor: monitor, current: current)).to be false
      end

      it 'returns false when removed is below threshold' do
        current = { pre_processed: 950, added: 0, removed: 50 }
        expect(described_class.exceeded?(monitor: monitor, current: current)).to be false
      end
    end
  end
end
