###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::PurgeArchivedReportDataService, type: :service do
  let(:report) do
    HudReports::ReportInstance.create!(
      report_name: 'System Performance Measures - FY 2026',
      user_id: User.system_user.id,
      state: 'Completed',
      completed_at: 90.days.ago,
      question_names: [],
    )
  end

  let(:config) do
    {
      report_cells_csv: {
        scope: -> { report.report_cells },
        filename: -> { 'cells.csv' },
        delete_order: 99,
      },
    }
  end

  before do
    allow(report).to receive(:archival_csv_config).and_return(config)
    report.update_column(
      :archival_metadata,
      {
        'archived_at' => 90.days.ago.iso8601,
        'purge_eligible_at' => 30.days.ago.iso8601,
        'expected_files' => ['report_cells_csv'],
        'expected_file_count' => 1,
      },
    )
    report.report_cells_csv.attach(
      io: StringIO.new("question,cell_name,universe\nQ1,A1,false"),
      filename: 'cells.csv',
      content_type: 'text/csv',
    )
    report.report_cells.create!(question: 'Q1', cell_name: 'A1', universe: false)
  end

  subject(:service) { described_class.new(report, dry_run: false, force: false) }

  describe '#purge!' do
    it 'fails when report is not in Completed state' do
      report.update_column(:state, 'Started')
      result = service.purge!
      expect(result[:success]).to be false
      expect(result[:errors].first).to match(/not been completed/i)
    end

    it 'fails when report is not archived' do
      allow(report).to receive(:archived?).and_return(false)
      result = service.purge!
      expect(result[:success]).to be false
    end

    it 'fails when grace period has not expired' do
      report.update_column(:archival_metadata, report.archival_metadata.merge('purge_eligible_at' => 10.days.from_now.iso8601))
      result = service.purge!
      expect(result[:success]).to be false
      expect(result[:errors].first).to match(/grace period/i)
    end

    it 'bypasses grace period when force: true' do
      report.update_column(:archival_metadata, report.archival_metadata.merge('purge_eligible_at' => 10.days.from_now.iso8601))
      force_service = described_class.new(report, dry_run: false, force: true)
      result = force_service.purge!
      expect(result[:success]).to be true
    end

    it 'fails when already purged' do
      report.update_column(:archival_metadata, report.archival_metadata.merge('purged_at' => Time.current.iso8601))
      result = service.purge!
      expect(result[:success]).to be false
    end

    it 'fails when expected CSV files are listed but not attached' do
      # Report appears archived (archived_at set), but detach the CSV
      report.report_cells_csv.purge
      # archived? checks both archived_at AND attachments, so stub it to simulate
      # archived_at being present while a file listed in expected_files is missing
      allow(report).to receive(:archived?).and_return(true)
      result = service.purge!
      expect(result[:success]).to be false
      expect(result[:errors].first).to match(/not accessible/i)
    end

    it 'fails when CSV row count does not match DB count' do
      # CSV has 1 row but DB has 2 cells
      report.report_cells.create!(question: 'Q2', cell_name: 'B1', universe: false)
      result = service.purge!
      expect(result[:success]).to be false
      expect(result[:errors].first).to match(/integrity/i)
    end

    it 'returns estimated counts in dry-run mode without deleting' do
      dry_service = described_class.new(report, dry_run: true, force: false)
      result = dry_service.purge!
      expect(result[:success]).to be true
      expect(result[:dry_run]).to be true
      expect(result[:would_delete]).to be_present
      expect(result[:would_delete]).to have_key(:household_contexts)
      expect(result[:would_delete]).to have_key(:checkpoints)
      expect(report.report_cells.count).to eq(1) # not deleted
    end

    it 'deletes records and sets purged_at on success' do
      result = service.purge!
      expect(result[:success]).to be true
      report.reload
      expect(report.archival_metadata['purged_at']).to be_present
      expect(report.report_cells.count).to eq(0)
    end

    it 'rolls back all deletions when an error occurs mid-purge' do
      # Force a failure after deletion but before mark_purged commits, to prove
      # the transaction restores rows to their pre-purge state.
      allow(service).to receive(:mark_purged).and_raise(ActiveRecord::StatementInvalid, 'simulated DB error')
      result = service.purge!
      expect(result[:success]).to be false
      expect(report.report_cells.count).to eq(1)
      report.reload
      expect(report.archival_metadata['purged_at']).to be_nil
    end

    it 'hard-deletes paranoid soft-deleted rows' do
      # Simulate reset_question soft-deleting cells during a retry
      HudReports::ReportCell.where(report_instance_id: report.id).update_all(deleted_at: Time.current)
      # A new live cell was created after the retry — CSV still has 1 row so integrity passes
      report.report_cells.create!(question: 'Q1', cell_name: 'A1', universe: false)

      result = service.purge!
      expect(result[:success]).to be true
      expect(HudReports::ReportCell.with_deleted.where(report_instance_id: report.id).count).to eq(0)
    end
  end
end
