###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReportArchival, type: :model do
  let(:purged_at) { 2.days.ago }

  let(:report) do
    HudReports::ReportInstance.create!(
      report_name: 'System Performance Measures - FY 2026',
      user_id: User.system_user.id,
      state: 'Completed',
      completed_at: 90.days.ago,
      question_names: [],
      archival_metadata: {
        'archived_at' => 3.days.ago.iso8601,
        'expected_files' => ['report_cells_csv'],
        'purged_at' => purged_at.iso8601,
      },
    )
  end

  describe '#remove_archival_metadata' do
    it 'deletes the keys rather than setting them to nil' do
      report.remove_archival_metadata('purged_at')

      expect(report.reload.archival_metadata).not_to have_key('purged_at')
      expect(report.archival_metadata).to have_key('archived_at')
    end

    it 'accepts symbols and multiple keys' do
      report.update_archival_metadata('restore_started_at', Time.current.iso8601)
      report.remove_archival_metadata(:restore_started_at, :purged_at)

      expect(report.reload.archival_metadata.keys).to contain_exactly('archived_at', 'expected_files')
    end
  end

  describe '#begin_restore!' do
    before do
      report.fail_restore!('an earlier failure')
      report.begin_restore!
    end

    it 'marks the report as restoring' do
      expect(report.reload).to be_restoring
    end

    it 'clears the previous failure' do
      expect(report.reload).not_to be_restore_failed
      expect(report.restore_error).to be_nil
    end
  end

  describe '#fail_restore!' do
    before { report.begin_restore! }

    it 'records the message and stops reporting as restoring' do
      report.fail_restore!('S3 file missing')

      expect(report.reload).to be_restore_failed
      expect(report.restore_error).to eq('S3 file missing')
      expect(report).not_to be_restoring
    end
  end

  describe '#finish_restore!' do
    before do
      report.begin_restore!
      report.remove_archival_metadata('purged_at') # what the restore service does on success
      report.finish_restore!
    end

    it 'removes every restore key' do
      keys = report.reload.archival_metadata.keys

      expect(keys).not_to include('restore_started_at', 'restore_failed_at', 'restore_error')
    end

    it 'leaves the archival state intact so the report can be purged again' do
      expect(report.reload.archival_metadata).to include('archived_at', 'expected_files')
    end
  end

  describe 'when the report is not purged' do
    let(:report_not_purged) do
      HudReports::ReportInstance.create!(
        report_name: 'System Performance Measures - FY 2026',
        user_id: User.system_user.id,
        state: 'Completed',
        completed_at: 90.days.ago,
        question_names: [],
        archival_metadata: {
          'archived_at' => 3.days.ago.iso8601,
          'restore_started_at' => 1.hour.ago.iso8601,
          'restore_failed_at' => 1.hour.ago.iso8601,
        },
      )
    end

    it 'reports neither restoring nor failed' do
      expect(report_not_purged).not_to be_restoring
      expect(report_not_purged).not_to be_restore_failed
    end
  end

  describe 'when a restore has been running longer than the stale cutoff' do
    # A worker killed or evicted mid-restore never runs its cleanup, so
    # restore_started_at stays set. Without the cutoff the page would show the
    # progress banner forever, with no button and no way out.
    let(:abandoned) do
      HudReports::ReportInstance.create!(
        report_name: 'System Performance Measures - FY 2026',
        user_id: User.system_user.id,
        state: 'Completed',
        completed_at: 90.days.ago,
        question_names: [],
        archival_metadata: {
          'archived_at' => 3.days.ago.iso8601,
          'purged_at' => 2.days.ago.iso8601,
          'restore_started_at' => (HudReportArchival::RESTORE_STALE_AFTER.ago - 1.minute).iso8601,
        },
      )
    end

    it 'no longer reports as restoring' do
      expect(abandoned).not_to be_restoring
    end

    it 'does not report as failed either, so the idle branch renders' do
      expect(abandoned).not_to be_restore_failed
    end

    it 'still reports as restoring just inside the cutoff' do
      abandoned.update_archival_metadata('restore_started_at', (HudReportArchival::RESTORE_STALE_AFTER.ago + 5.minutes).iso8601)

      expect(abandoned.reload).to be_restoring
    end
  end

  describe 'when restore state predates the current purge' do
    # An SPM restored via the HUD report page (which does not know about these keys)
    # and then re-purged by the nightly task must present as purged-and-idle.
    let(:re_purged) do
      HudReports::ReportInstance.create!(
        report_name: 'System Performance Measures - FY 2026',
        user_id: User.system_user.id,
        state: 'Completed',
        completed_at: 90.days.ago,
        question_names: [],
        archival_metadata: {
          'archived_at' => 30.days.ago.iso8601,
          'restore_started_at' => 10.days.ago.iso8601,
          'restore_failed_at' => 10.days.ago.iso8601,
          'restore_error' => 'a failure from a previous purge cycle',
          'purged_at' => 1.day.ago.iso8601,
        },
      )
    end

    it 'ignores the stale restore state' do
      expect(re_purged).not_to be_restoring
      expect(re_purged).not_to be_restore_failed
    end
  end
end
