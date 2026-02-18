# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Monitoring::CsvRowCountCalculator do
  let(:data_source) { create(:grda_warehouse_data_source) }

  describe '.current_value' do
    it 'returns empty hash when importer_log is blank' do
      expect(described_class.current_value(importer_log: nil, csv_file_name: 'Client.csv')).to eq({})
    end

    it 'returns empty hash when summary is blank' do
      log = HmisCsvImporter::Importer::ImporterLog.new(summary: {})
      expect(described_class.current_value(importer_log: log, csv_file_name: 'Client.csv')).to eq({})
    end

    it 'returns empty hash when csv_file_name not in summary' do
      log = HmisCsvImporter::Importer::ImporterLog.new(summary: { 'Export.csv' => {} })
      expect(described_class.current_value(importer_log: log, csv_file_name: 'Client.csv')).to eq({})
    end

    it 'extracts pre_processed, added, removed from summary' do
      log = HmisCsvImporter::Importer::ImporterLog.new(
        summary: {
          'Client.csv' => {
            'pre_processed' => 1500,
            'added' => 50,
            'removed' => 10,
          },
        },
      )
      result = described_class.current_value(importer_log: log, csv_file_name: 'Client.csv')
      expect(result).to eq(pre_processed: 1500, added: 50, removed: 10)
    end

    it 'coerces string values to integers' do
      log = HmisCsvImporter::Importer::ImporterLog.new(
        summary: {
          'Client.csv' => {
            'pre_processed' => '2000',
            'added' => '100',
            'removed' => '25',
          },
        },
      )
      result = described_class.current_value(importer_log: log, csv_file_name: 'Client.csv')
      expect(result).to eq(pre_processed: 2000, added: 100, removed: 25)
    end
  end

  describe '.previous_value' do
    it 'returns nil when no previous import exists' do
      current_log = create(:hmis_csv_importer_log, data_source: data_source, status: 'complete')
      result = described_class.previous_value(
        data_source: data_source,
        csv_file_name: 'Client.csv',
        exclude_importer_log_id: current_log.id,
      )
      expect(result).to be_nil
    end

    it 'returns values from the most recent prior completed import' do
      current_log = create(:hmis_csv_importer_log, data_source: data_source, status: 'complete')
      create(
        :hmis_csv_importer_log,
        data_source: data_source,
        status: 'complete',
        completed_at: 1.day.ago,
        summary: {
          'Client.csv' => { 'pre_processed' => 1400, 'added' => 0, 'removed' => 0 },
        },
      )
      result = described_class.previous_value(
        data_source: data_source,
        csv_file_name: 'Client.csv',
        exclude_importer_log_id: current_log.id,
      )
      expect(result).to eq(pre_processed: 1400, added: 0, removed: 0)
    end
  end
end
