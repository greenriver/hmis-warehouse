# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::ImportCsvMonitor, type: :model do
  let(:data_source) { create(:grda_warehouse_data_source) }

  describe 'validations' do
    it 'requires at least one threshold' do
      monitor = described_class.new(
        data_source: data_source,
        csv_file_name: 'Client.csv',
      )
      expect(monitor).not_to be_valid
      message = 'At least one numeric threshold must be set'
      described_class::THRESHOLD_ATTRS.each do |attr|
        expect(monitor.errors[attr]).to include(message)
      end
    end

    it 'is valid with count_increase_threshold' do
      monitor = described_class.new(
        data_source: data_source,
        csv_file_name: 'Client.csv',
        count_increase_threshold: 10,
      )
      expect(monitor).to be_valid
    end

    it 'is valid with min_additions_threshold' do
      monitor = described_class.new(
        data_source: data_source,
        csv_file_name: 'Services.csv',
        min_additions_threshold: 500,
      )
      expect(monitor).to be_valid
    end

    it 'is valid with max_removals_threshold' do
      monitor = described_class.new(
        data_source: data_source,
        csv_file_name: 'Enrollment.csv',
        max_removals_threshold: 100,
      )
      expect(monitor).to be_valid
    end

    it 'rejects invalid csv_file_name' do
      monitor = described_class.new(
        data_source: data_source,
        csv_file_name: 'Invalid.csv',
        count_increase_threshold: 10,
      )
      expect(monitor).not_to be_valid
      expect(monitor.errors[:csv_file_name]).to be_present
    end
  end

  describe '#threshold_exceeded?' do
    let(:monitor) do
      create(:grda_warehouse_import_csv_monitor,
             count_increase_threshold: 50,
             count_decrease_threshold: 50)
    end

    it 'returns false when previous is nil' do
      current = { pre_processed: 1000, added: 100, removed: 0 }
      expect(monitor.threshold_exceeded?(current: current, previous: nil)).to be false
    end

    it 'returns false when change is within threshold' do
      current = { pre_processed: 1020, added: 20, removed: 0 }
      previous = { pre_processed: 1000, added: 0, removed: 0 }
      expect(monitor.threshold_exceeded?(current: current, previous: previous)).to be false
    end

    it 'returns hash when count increase exceeds threshold' do
      current = { pre_processed: 1060, added: 60, removed: 0 }
      previous = { pre_processed: 1000, added: 0, removed: 0 }
      result = monitor.threshold_exceeded?(current: current, previous: previous)
      expect(result).to be_a(Hash)
      expect(result[:reason]).to eq(:delta_increase)
      expect(result[:change_count]).to eq(60)
    end

    it 'returns hash when count decrease exceeds threshold' do
      current = { pre_processed: 940, added: 0, removed: 60 }
      previous = { pre_processed: 1000, added: 0, removed: 0 }
      result = monitor.threshold_exceeded?(current: current, previous: previous)
      expect(result).to be_a(Hash)
      expect(result[:reason]).to eq(:delta_decrease)
      expect(result[:change_count]).to eq(-60)
    end

    it 'returns false when only increase thresholds set and change is negative' do
      monitor.update!(count_decrease_threshold: nil)
      current = { pre_processed: 900, added: 0, removed: 100 }
      previous = { pre_processed: 1000, added: 0, removed: 0 }
      expect(monitor.threshold_exceeded?(current: current, previous: previous)).to be false
    end

    it 'returns false when only decrease thresholds set and change is positive' do
      monitor.update!(count_increase_threshold: nil)
      current = { pre_processed: 1100, added: 100, removed: 0 }
      previous = { pre_processed: 1000, added: 0, removed: 0 }
      expect(monitor.threshold_exceeded?(current: current, previous: previous)).to be false
    end

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
        result = monitor.threshold_exceeded?(current: current, previous: nil)
        expect(result).to be_a(Hash)
        expect(result[:reason]).to eq(:min_additions)
        expect(result[:added]).to eq(200)
        expect(result[:threshold]).to eq(500)
      end

      it 'returns false when added meets or exceeds threshold' do
        current = { pre_processed: 1000, added: 500, removed: 0 }
        expect(monitor.threshold_exceeded?(current: current, previous: nil)).to be false
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
        result = monitor.threshold_exceeded?(current: current, previous: nil)
        expect(result).to be_a(Hash)
        expect(result[:reason]).to eq(:max_removals)
        expect(result[:removed]).to eq(150)
        expect(result[:threshold]).to eq(100)
      end

      it 'returns false when removed is at or below threshold' do
        current = { pre_processed: 950, added: 0, removed: 50 }
        expect(monitor.threshold_exceeded?(current: current, previous: nil)).to be false
      end
    end
  end
end
