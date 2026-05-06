###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe HudReports::RestoreArchivedReportDataService, type: :service do
  let(:report) do
    HudReports::ReportInstance.create!(
      report_name: 'System Performance Measures - FY 2026',
      user_id: User.system_user.id,
      state: 'Completed',
      completed_at: 90.days.ago,
      question_names: [],
    )
  end

  let(:table_metadata) do
    {
      'row_labels' => ['Row 1', 'Row 2'],
      'first_column' => 'B',
      'last_column' => 'C',
      'first_row' => 1,
      'last_row' => 2,
      'header_row' => ['', 'Column B', 'Column C'],
    }
  end

  let!(:universe_cell) do
    report.report_cells.create!(
      question: 'Q1',
      cell_name: nil,
      universe: true,
      metadata: { 'tables' => ['Q1a'] },
    )
  end

  let!(:table_root_cell) do
    report.report_cells.create!(
      question: 'Q1a',
      cell_name: nil,
      universe: false,
      metadata: table_metadata,
      status: 'Completed',
    )
  end

  let!(:data_cell) do
    report.report_cells.create!(
      question: 'Q1a',
      cell_name: 'B1',
      universe: false,
      summary: 42,
      status: 'Completed',
      any_members: true,
    )
  end

  # original_cell kept for backward-compatible tests
  let!(:original_cell) { data_cell }

  def build_csv(cells)
    col_names = HudReports::ReportCell.column_names
    CSV.generate do |csv|
      csv << col_names
      cells.each { |cell| csv << col_names.map { |c| cell[c].is_a?(Hash) || cell[c].is_a?(Array) ? cell[c].to_json : cell[c] } }
    end
  end

  before do
    csv_content = build_csv([universe_cell, table_root_cell, data_cell])

    report.report_cells_csv.attach(
      io: StringIO.new(csv_content),
      filename: 'cells.csv',
      content_type: 'text/csv',
    )
    report.update_column(:archival_metadata, {
                           'archived_at' => 91.days.ago.iso8601,
                           'purged_at' => 90.days.ago.iso8601,
                           'expected_files' => ['report_cells_csv'],
                         })
    allow(report).to receive(:archival_csv_config).and_return(
      report_cells_csv: {
        scope: -> { report.report_cells },
        filename: -> { 'cells.csv' },
        delete_order: 99,
      },
    )
    # Simulate purged state — hard delete so upsert_all can restore the same IDs
    HudReports::ReportCell.unscoped.where(report_instance_id: report.id).delete_all
  end

  subject(:service) { described_class.new(report) }

  describe '#restore!' do
    it 'returns failure when report is not archived' do
      allow(report).to receive(:archived?).and_return(false)
      result = service.restore!
      expect(result[:success]).to be false
    end

    it 'reinserts records from CSV' do
      service.restore!
      expect(report.report_cells.count).to eq(3)
    end

    it 'preserves original primary keys' do
      service.restore!
      restored_ids = report.report_cells.pluck(:id).sort
      expect(restored_ids).to eq([universe_cell.id, table_root_cell.id, data_cell.id].sort)
    end

    it 'restores json metadata column as a Hash (not a String)' do
      service.restore!
      restored = report.existing_universe('Q1')
      expect(restored).to be_present
      expect(restored.metadata).to be_a(Hash)
      expect(restored.metadata['tables']).to eq(['Q1a'])
    end

    it 'restores a plain string in a jsonb summary column' do
      # Simulate an archive created before the fix: bare "CocCode" in the CSV,
      # not the JSON-encoded '"CocCode"'. The restore must fall back to the raw
      # string rather than returning nil from a failed JSON.parse.
      col_names = HudReports::ReportCell.column_names
      old_style_csv = CSV.generate do |csv|
        csv << col_names
        [universe_cell, table_root_cell, data_cell].each do |cell|
          csv << col_names.map do |c|
            val = cell[c]
            # Deliberately write summary as a bare string
            if c == 'summary'
              val
            elsif val.is_a?(Hash) || val.is_a?(Array)
              val.to_json
            else
              val
            end
          end
        end
        # Add a cell with a plain-string summary to simulate HDX metadata cells
        string_cell = report.report_cells.create!(question: 'csv', cell_name: 'A1', universe: false, summary: 'CocCode')
        csv << col_names.map { |c| c == 'summary' ? 'CocCode' : string_cell[c] }
      end

      report.report_cells_csv.attach(io: StringIO.new(old_style_csv), filename: 'old.csv', content_type: 'text/csv')
      report.update_column(:archival_metadata, report.archival_metadata.merge('expected_files' => ['report_cells_csv']))
      HudReports::ReportCell.unscoped.where(report_instance_id: report.id).delete_all

      described_class.new(report).restore!

      restored = HudReports::ReportCell.unscoped.find_by(report_instance_id: report.id, question: 'csv', cell_name: 'A1')
      expect(restored).to be_present
      expect(restored.summary).to eq('CocCode')
    end

    it 'restores table-root cell metadata so CsvExporter can render tables' do
      service.restore!
      root = report.answer(question: 'Q1a')
      expect(root.metadata).to be_a(Hash)
      expect(root.metadata['first_column']).to eq('B')
      expect(root.metadata['row_labels']).to eq(['Row 1', 'Row 2'])
    end

    it 'restores summary and any_members on data cells' do
      service.restore!
      cell = report.answer(question: 'Q1a', cell: 'B1')
      expect(cell.summary).to eq(42)
      expect(cell.any_members).to be true
    end

    it 'is idempotent — re-running upsert_all on already-restored rows does not duplicate records' do
      service.restore!
      # CSV files and archived_at are preserved, so a second restore runs directly.
      described_class.new(report).restore!
      expect(report.report_cells.count).to eq(3)
    end

    it 'clears purged_at but preserves archived_at and CSV attachments after restore' do
      service.restore!
      report.reload
      expect(report.archival_metadata['purged_at']).to be_nil
      expect(report.archival_metadata['archived_at']).to be_present
      expect(report.report_cells_csv.attached?).to be true
    end

    it 'resets the DB sequence so new records do not conflict' do
      service.restore!
      expect do
        report.report_cells.create!(question: 'Q2', cell_name: 'B1', universe: false)
      end.not_to raise_error
    end
  end
end
