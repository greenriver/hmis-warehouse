###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudLsa::Generators::Fy2026::LsaComparisonTool do
  around(:each) do |example|
    Dir.mktmpdir do |dir|
      @sample_dir = File.join(dir, 'sample')
      @generated_dir = File.join(dir, 'generated')
      FileUtils.mkdir_p(@sample_dir)
      FileUtils.mkdir_p(@generated_dir)
      example.run
    end
  end

  def write_csv(dir, filename, rows)
    CSV.open(File.join(dir, filename), 'w') do |csv|
      csv << rows.first.keys
      rows.each { |row| csv << row.values }
    end
  end

  describe '#compare without skips' do
    it 'reports rows present only in the sample and only in the generated output' do
      write_csv(
        @sample_dir, 'Funder.csv',
        [
          { 'FunderID' => 'F1', 'Funder' => '2', 'StartDate' => '2020-01-01' },
          { 'FunderID' => 'F2', 'Funder' => '3', 'StartDate' => '2021-01-01' },
        ]
      )
      write_csv(
        @generated_dir, 'Funder.csv', [
          { 'FunderID' => 'F1', 'Funder' => '2', 'StartDate' => '2020-01-01' },
          { 'FunderID' => 'F3', 'Funder' => '9', 'StartDate' => '2022-01-01' },
        ]
      )

      diffs = described_class.new(@sample_dir, @generated_dir).compare
      diff = diffs.fetch(File.join(@sample_dir, 'Funder.csv'))

      # FunderID is dropped via removed_keys, so only Funder/StartDate distinguish rows
      expect(diff['sample - generated']).to contain_exactly(['3', '2021-01-01'])
      expect(diff['generated - sample']).to contain_exactly(['9', '2022-01-01'])
    end
  end

  describe '#compare with a column skip' do
    it 'ignores differences in the skipped column but still catches differences elsewhere' do
      write_csv(
        @sample_dir, 'LSAReport.csv', [
          { 'ReportCoC' => 'XX-501', 'NoCoC' => '12', 'HouseholdEntry' => '100' },
        ]
      )
      write_csv(
        @generated_dir, 'LSAReport.csv', [
          { 'ReportCoC' => 'XX-501', 'NoCoC' => '0', 'HouseholdEntry' => '100' },
        ]
      )

      skips = { 'LSAReport.csv' => { columns: ['NoCoC'] } }
      diffs = described_class.new(@sample_dir, @generated_dir, skips: skips).compare
      diff = diffs.fetch(File.join(@sample_dir, 'LSAReport.csv'))

      expect(diff['sample - generated']).to be_empty
      expect(diff['generated - sample']).to be_empty
    end

    it 'still reports a mismatch in a column that was not skipped' do
      write_csv(
        @sample_dir, 'LSAReport.csv', [
          { 'ReportCoC' => 'XX-501', 'NoCoC' => '12', 'HouseholdEntry' => '100' },
        ]
      )
      write_csv(
        @generated_dir, 'LSAReport.csv', [
          { 'ReportCoC' => 'XX-501', 'NoCoC' => '0', 'HouseholdEntry' => '99' },
        ]
      )

      skips = { 'LSAReport.csv' => { columns: ['NoCoC'] } }
      diffs = described_class.new(@sample_dir, @generated_dir, skips: skips).compare
      diff = diffs.fetch(File.join(@sample_dir, 'LSAReport.csv'))

      expect(diff['sample - generated']).to contain_exactly(['XX-501', '100'])
      expect(diff['generated - sample']).to contain_exactly(['XX-501', '99'])
    end
  end

  describe '#compare with a row skip' do
    it 'drops only the row matching the skip key/value, leaving other rows to compare normally' do
      write_csv(
        @sample_dir, 'LSACalculated.csv', [
          { 'Value' => '3', 'ReportRow' => '905', 'Step' => '10.4' },
          { 'Value' => '7', 'ReportRow' => '900', 'Step' => '10.1' },
        ]
      )
      write_csv(
        @generated_dir, 'LSACalculated.csv', [
          { 'Value' => '7', 'ReportRow' => '900', 'Step' => '10.1' },
        ]
      )

      skips = { 'LSACalculated.csv' => { rows: { 'ReportRow' => ['905'] } } }
      diffs = described_class.new(@sample_dir, @generated_dir, skips: skips).compare
      diff = diffs.fetch(File.join(@sample_dir, 'LSACalculated.csv'))

      expect(diff['sample - generated']).to be_empty
      expect(diff['generated - sample']).to be_empty
    end

    it 'still reports a genuine mismatch on a row whose key does not match the skip' do
      write_csv(
        @sample_dir, 'LSACalculated.csv', [
          { 'Value' => '3', 'ReportRow' => '905', 'Step' => '10.4' },
          { 'Value' => '7', 'ReportRow' => '900', 'Step' => '10.1' },
        ]
      )
      write_csv(
        @generated_dir, 'LSACalculated.csv', [
          { 'Value' => '8', 'ReportRow' => '900', 'Step' => '10.1' },
        ]
      )

      skips = { 'LSACalculated.csv' => { rows: { 'ReportRow' => ['905'] } } }
      diffs = described_class.new(@sample_dir, @generated_dir, skips: skips).compare
      diff = diffs.fetch(File.join(@sample_dir, 'LSACalculated.csv'))

      expect(diff['sample - generated']).to contain_exactly(['7', '900', '10.1'])
      expect(diff['generated - sample']).to contain_exactly(['8', '900', '10.1'])
    end
  end

  describe '#compare with skip_file' do
    it 'excludes the file from the comparison and records it as skipped, without affecting other files' do
      write_csv(@sample_dir, 'Funder.csv', [{ 'FunderID' => 'F1', 'Funder' => '2' }])
      write_csv(@generated_dir, 'Funder.csv', [{ 'FunderID' => 'F1', 'Funder' => '999' }])
      write_csv(@sample_dir, 'Project.csv', [{ 'ProjectID' => 'P1', 'ProjectName' => 'A' }])
      write_csv(@generated_dir, 'Project.csv', [{ 'ProjectID' => 'P1', 'ProjectName' => 'A' }])

      tool = described_class.new(@sample_dir, @generated_dir, skips: { 'Funder.csv' => { skip_file: true } })
      diffs = tool.compare

      expect(tool.skipped_files).to contain_exactly('Funder.csv')
      expect(diffs.keys.map { |path| File.basename(path) }).to contain_exactly('Project.csv')
      expect(diffs.fetch(File.join(@sample_dir, 'Project.csv'))['sample - generated']).to be_empty
    end
  end
end
