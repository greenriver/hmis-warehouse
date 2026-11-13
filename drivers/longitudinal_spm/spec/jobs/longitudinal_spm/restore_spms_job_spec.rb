###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LongitudinalSpm::RestoreSpmsJob, type: :job do
  let!(:user) { create :user }
  let!(:report) { LongitudinalSpm::Report.create!(user_id: user.id) }

  def build_spm(purged:, start_date:)
    metadata = { 'archived_at' => 3.days.ago.iso8601, 'expected_files' => ['report_cells_csv'] }
    metadata['purged_at'] = 2.days.ago.iso8601 if purged

    hud_spm = HudReports::ReportInstance.create!(
      report_name: HudSpmReport.current_generator.title,
      question_names: ['Measure 1'],
      user_id: user.id,
      state: 'Completed',
      completed_at: Time.current,
      archival_metadata: metadata,
    )
    LongitudinalSpm::Spm.create!(
      report_id: report.id,
      spm_id: hud_spm.id,
      start_date: start_date,
      end_date: start_date.to_date + 1.year - 1.day,
    )
    hud_spm
  end

  let!(:purged_one) { build_spm(purged: true, start_date: '2023-01-01') }
  let!(:purged_two) { build_spm(purged: true, start_date: '2024-01-01') }
  let!(:intact) { build_spm(purged: false, start_date: '2025-01-01') }

  # Stands in for RestoreArchivedReportDataService, whose real work needs S3 CSVs.
  # It mimics the contract this job depends on: never raises, returns a result
  # hash, and removes purged_at itself on success.
  def stub_restore_service(&behavior)
    allow(HudReports::RestoreArchivedReportDataService).to receive(:new) do |instance|
      double(restore!: behavior.call(instance))
    end
  end

  def succeed_for(instance)
    instance.remove_archival_metadata('purged_at')
    { success: true, restored_counts: { report_cells_csv: 5 } }
  end

  describe 'when every restore succeeds' do
    before do
      stub_restore_service { |instance| succeed_for(instance) }
      described_class.perform_now(report_id: report.id)
    end

    it 'restores every purged backing SPM' do
      expect(purged_one.reload).not_to be_purged
      expect(purged_two.reload).not_to be_purged
    end

    it 'leaves no restore state behind' do
      expect(purged_one.reload.archival_metadata.keys).
        not_to include('restore_started_at', 'restore_failed_at', 'restore_error')
    end

    it 'does not touch an SPM that was never purged' do
      expect(intact.reload.archival_metadata).not_to have_key('restore_started_at')
    end
  end

  describe 'when one restore fails' do
    before do
      stub_restore_service do |instance|
        if instance.id == purged_one.id
          { success: false, errors: ['universe_members_csv is not attached'] }
        else
          succeed_for(instance)
        end
      end
      described_class.perform_now(report_id: report.id)
    end

    it 'records the failure on the SPM that failed' do
      expect(purged_one.reload).to be_restore_failed
      expect(purged_one.restore_error).to eq('universe_members_csv is not attached')
    end

    it 'still restores the other SPMs' do
      expect(purged_two.reload).not_to be_purged
    end
  end

  describe 'when the job dies partway through' do
    before do
      allow(HudReports::RestoreArchivedReportDataService).to receive(:new).
        and_raise(ActiveRecord::StatementInvalid, 'connection lost')
    end

    it 're-raises so the job is retried' do
      expect { described_class.perform_now(report_id: report.id) }.
        to raise_error(ActiveRecord::StatementInvalid)
    end

    it 'leaves no SPM stuck in the restoring state' do
      suppress(ActiveRecord::StatementInvalid) { described_class.perform_now(report_id: report.id) }

      expect(purged_one.reload).not_to be_restoring
      expect(purged_two.reload).not_to be_restoring
    end
  end
end
