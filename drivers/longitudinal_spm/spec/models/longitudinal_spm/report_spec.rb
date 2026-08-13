###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LongitudinalSpm::Report, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let!(:user) { create :user }

  describe 'default report' do
    it 'running the report with default values does not fail' do
      report = LongitudinalSpm::Report.new(
        user_id: user.id,
      )
      expect { report.run_and_save! }.not_to raise_error
    end
  end

  describe 'when the backing SPMs have been archived and purged' do
    # A purged SPM keeps its state of Completed, but its report_cells (and the metadata
    # that holds the row and column labels) are gone from the database.
    let!(:report) { LongitudinalSpm::Report.create!(user_id: user.id) }
    let!(:hud_spm) do
      HudReports::ReportInstance.create!(
        report_name: HudSpmReport.current_generator.title,
        question_names: ['Measure 1'],
        user_id: user.id,
        state: 'Completed',
        completed_at: Time.current,
        archival_metadata: { 'purged_at' => Time.current.iso8601 },
      )
    end
    let!(:spm) do
      LongitudinalSpm::Spm.create!(
        report_id: report.id,
        spm_id: hud_spm.id,
        start_date: '2023-01-01',
        end_date: '2023-12-31',
      )
    end

    it 'returns a blank label instead of raising' do
      expect(report.spm_describe('1a', 'D2')).to eq('')
      expect(report.spm_describe('1a', 'D2', :col)).to eq('')
    end

    it 'does not add report cells back to the purged SPM' do
      report.spm_describe('1a', 'D2')
      expect(hud_spm.report_cells.count).to eq(0)
    end

    it 'identifies the purged SPM so the view can flag it' do
      expect(report.purged_spms.map(&:id)).to eq([spm.id])
    end
  end

  describe 'when the backing SPMs still have their data' do
    let!(:report) { LongitudinalSpm::Report.create!(user_id: user.id) }
    let!(:hud_spm) do
      HudReports::ReportInstance.create!(
        report_name: HudSpmReport.current_generator.title,
        question_names: ['Measure 1'],
        user_id: user.id,
        state: 'Completed',
        completed_at: Time.current,
      )
    end
    let!(:spm) do
      LongitudinalSpm::Spm.create!(
        report_id: report.id,
        spm_id: hud_spm.id,
        start_date: '2023-01-01',
        end_date: '2023-12-31',
      )
    end

    it 'reports no purged SPMs' do
      expect(report.purged_spms).to be_empty
    end

    it 'returns the stored label' do
      hud_spm.report_cells.create!(
        question: '1a',
        cell_name: nil,
        universe: false,
        # header_row is indexed by column letter, so 'D' lands on index 3
        metadata: { 'row_labels' => ['Persons in ES', 'Persons in TH'], 'header_row' => ['', 'B', 'C', 'Current'] },
      )
      expect(report.spm_describe('1a', 'D2')).to eq('Persons in ES')
      expect(report.spm_describe('1a', 'D2', :col)).to eq('Current')
    end
  end
end
