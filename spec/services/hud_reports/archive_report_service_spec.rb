###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::ArchiveReportService, type: :service do
  let(:report) do
    HudReports::ReportInstance.create!(
      report_name: 'System Performance Measures - FY 2026',
      user_id: User.system_user.id,
      state: 'Completed',
      completed_at: 10.days.ago,
      question_names: [],
    )
  end

  before do
    report.report_cells.create!(question: 'TestQ', cell_name: 'A1', universe: false)
    allow(report).to receive(:archival_csv_config).and_return(
      report_cells_csv: {
        scope: -> { report.report_cells },
        filename: -> { "cells-#{report.id}.csv" },
        delete_order: 99,
      },
    )
  end

  describe '#archive!' do
    subject(:service) { described_class.new(report) }

    it 'returns false when archival_csv_config is empty' do
      allow(report).to receive(:archival_csv_config).and_return({})
      expect(service.archive!).to be false
    end

    it 'attaches a CSV file for each config entry' do
      service.archive!
      expect(report.report_cells_csv.attached?).to be true
    end

    it 'sets archived_at in archival_metadata' do
      service.archive!
      report.reload
      expect(report.archival_metadata['archived_at']).to be_present
    end

    it 'sets expected_files in archival_metadata' do
      service.archive!
      report.reload
      expect(report.archival_metadata['expected_files']).to include('report_cells_csv')
    end

    it 'restores updated_at after archival' do
      original_updated_at = report.updated_at
      service.archive!
      report.reload
      expect(report.updated_at).to be_within(1.second).of(original_updated_at)
    end

    it 'is idempotent — skips already-attached files on second call' do
      service.archive!
      blob_before = report.reload.report_cells_csv.blob

      service.archive!
      blob_after = report.reload.report_cells_csv.blob

      expect(blob_after.id).to eq(blob_before.id)
    end

    context 'when CSV is empty (zero rows)' do
      before { report.report_cells.delete_all }

      it 'still attaches a CSV (with header only) and does not raise' do
        expect { service.archive! }.not_to raise_error
        report.reload
        expect(report.report_cells_csv.attached?).to be true
      end
    end

    it 'returns false and populates errors when a scope lambda raises' do
      broken_config = {
        report_cells_csv: {
          scope: -> { raise 'simulated storage failure' },
          filename: -> { 'cells.csv' },
          delete_order: 99,
        },
      }
      allow(report).to receive(:archival_csv_config).and_return(broken_config)

      result = service.archive!
      expect(result).to be false
      expect(service.errors).not_to be_empty
    end

    it 'stores generator_class in archival_metadata when a generator is registered' do
      fake_klass = Class.new
      allow(report).to receive(:archival_generator_klass).and_return(fake_klass)
      # Stub name since anonymous classes return nil for .name
      allow(fake_klass).to receive(:name).and_return('MyApp::FakeGenerator')

      service.archive!
      report.reload
      expect(report.archival_metadata['generator_class']).to eq('MyApp::FakeGenerator')
    end

    it 'skips generator_class when no generator is registered' do
      allow(report).to receive(:archival_generator_klass).and_return(nil)
      service.archive!
      report.reload
      expect(report.archival_metadata.key?('generator_class')).to be false
    end

    it 'writes CSV with all columns including id' do
      service.archive!
      # Read the attached CSV and check headers
      report.reload
      headers = nil
      report.report_cells_csv.open do |file|
        headers = file.readline.chomp.split(',')
      end
      expect(headers).to include('id')
    end

    it 'JSON-encodes string values in jsonb columns so they survive the restore round-trip' do
      # summary is a jsonb column. Plain strings like "CocCode" are not valid JSON,
      # so JSON.parse("CocCode") raises and ActiveRecord::Type::Json returns nil —
      # wiping the value on restore. The archive must write '"CocCode"' (JSON-encoded).
      cell = report.report_cells.first
      cell.update_column(:summary, 'CocCode')

      service.archive!
      report.reload

      rows = []
      report.report_cells_csv.open do |file|
        csv = CSV.parse(file.read, headers: true)
        rows = csv.map(&:to_h)
      end

      summary_values = rows.map { |r| r['summary'] }
      # The CSV must contain '"CocCode"' (JSON string literal) not 'CocCode' (bare word)
      expect(summary_values).to include('"CocCode"')
      expect(summary_values).not_to include('CocCode')
    end
  end
end
