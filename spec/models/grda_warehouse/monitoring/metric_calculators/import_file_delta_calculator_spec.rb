# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Monitoring::MetricCalculators::ImportFileDeltaCalculator do
  let(:data_source) { create(:grda_warehouse_data_source) }

  describe '.exceeded?' do
    context 'with count_increase_threshold' do
      let(:monitor) do
        create(:grda_warehouse_import_csv_monitor,
               data_source: data_source,
               count_increase_threshold: 50,
               count_decrease_threshold: nil)
      end

      it 'returns false when previous is nil' do
        current = { pre_processed: 1100, added: 100, removed: 0 }
        expect(described_class.exceeded?(monitor: monitor, current: current, previous: nil)).to be false
      end

      it 'returns false when increase is below threshold' do
        current = { pre_processed: 1040, added: 40, removed: 0 }
        previous = { pre_processed: 1000, added: 0, removed: 0 }
        expect(described_class.exceeded?(monitor: monitor, current: current, previous: previous)).to be false
      end

      it 'returns hash when increase meets threshold' do
        current = { pre_processed: 1060, added: 60, removed: 0 }
        previous = { pre_processed: 1000, added: 0, removed: 0 }
        result = described_class.exceeded?(monitor: monitor, current: current, previous: previous)
        expect(result).to eq(
          reason: :delta_increase,
          change_count: 60,
          previous_count: 1000,
          current_count: 1060,
        )
      end
    end

    context 'with count_decrease_threshold' do
      let(:monitor) do
        create(:grda_warehouse_import_csv_monitor,
               data_source: data_source,
               count_increase_threshold: nil,
               count_decrease_threshold: 50)
      end

      it 'returns false when decrease is below threshold' do
        current = { pre_processed: 960, added: 0, removed: 40 }
        previous = { pre_processed: 1000, added: 0, removed: 0 }
        expect(described_class.exceeded?(monitor: monitor, current: current, previous: previous)).to be false
      end

      it 'returns hash when decrease meets threshold' do
        current = { pre_processed: 940, added: 0, removed: 60 }
        previous = { pre_processed: 1000, added: 0, removed: 0 }
        result = described_class.exceeded?(monitor: monitor, current: current, previous: previous)
        expect(result).to eq(
          reason: :delta_decrease,
          change_count: -60,
          previous_count: 1000,
          current_count: 940,
        )
      end
    end
  end
end
