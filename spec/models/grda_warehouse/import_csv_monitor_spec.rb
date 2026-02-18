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
      expect(monitor.errors[:base]).to include('At least one threshold (count or percent) must be set')
    end

    it 'is valid with count_increase_threshold' do
      monitor = described_class.new(
        data_source: data_source,
        csv_file_name: 'Client.csv',
        count_increase_threshold: 10,
      )
      expect(monitor).to be_valid
    end

    it 'is valid with percent_decrease_threshold' do
      monitor = described_class.new(
        data_source: data_source,
        csv_file_name: 'Client.csv',
        percent_decrease_threshold: 15,
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

    it 'returns true when count increase exceeds threshold' do
      current = { pre_processed: 1060, added: 60, removed: 0 }
      previous = { pre_processed: 1000, added: 0, removed: 0 }
      expect(monitor.threshold_exceeded?(current: current, previous: previous)).to be true
    end

    it 'returns true when count decrease exceeds threshold' do
      current = { pre_processed: 940, added: 0, removed: 60 }
      previous = { pre_processed: 1000, added: 0, removed: 0 }
      expect(monitor.threshold_exceeded?(current: current, previous: previous)).to be true
    end

    it 'returns false when only increase thresholds set and change is negative' do
      monitor.update!(count_decrease_threshold: nil, percent_decrease_threshold: nil)
      current = { pre_processed: 900, added: 0, removed: 100 }
      previous = { pre_processed: 1000, added: 0, removed: 0 }
      expect(monitor.threshold_exceeded?(current: current, previous: previous)).to be false
    end

    it 'returns false when only decrease thresholds set and change is positive' do
      monitor.update!(count_increase_threshold: nil, percent_increase_threshold: nil)
      current = { pre_processed: 1100, added: 100, removed: 0 }
      previous = { pre_processed: 1000, added: 0, removed: 0 }
      expect(monitor.threshold_exceeded?(current: current, previous: previous)).to be false
    end
  end
end
