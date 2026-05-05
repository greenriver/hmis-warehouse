###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'report_csv_reader'

# Integration tests: full archive → purge → restore cycle against real DB.
# No mocks. Verifies CSV row counts, deletion, and restore integrity.
RSpec.describe 'SPM Archival Integration', type: :model do
  # Force autoload all generators so their `include HudSpmReport::Archival`
  # runs and registers them in HudReportArchival.generator_registry.
  before(:all) do
    _ = HudSpmReport::Generators::Fy2020::Generator
    _ = HudSpmReport::Generators::Fy2023::Generator
    _ = HudSpmReport::Generators::Fy2024::Generator
    _ = HudSpmReport::Generators::Fy2026::Generator
  end

  def create_completed_report(report_name)
    HudReports::ReportInstance.create!(
      report_name: report_name,
      user_id: User.system_user.id,
      state: 'Completed',
      completed_at: 90.days.ago,
      question_names: [],
    )
  end

  def run_archive_purge_restore_cycle(report)
    generator = report.archival_generator_klass
    expect(generator).to be_present, "No generator registered for '#{report.report_name}'"

    config = generator.archival_csv_config(report)
    expect(config).to be_present

    # Capture DB counts before archival
    before_counts = config.transform_values { |entry| entry[:scope].call.count }

    # ── Archive ──────────────────────────────────────────────────────────────
    archive_service = HudReports::ArchiveReportService.new(report)
    expect(archive_service.archive!).to be(true), "Archive failed: #{archive_service.errors.inspect}"
    report.reload
    expect(report.archived?).to be true

    # Verify CSV row counts match DB counts captured before archival
    config.each do |name, _entry|
      csv_count = ReportCsvReader.new(report, name).count
      db_count = before_counts[name]
      expect(csv_count).to eq(db_count),
                           "CSV count mismatch for #{name}: CSV=#{csv_count}, DB=#{db_count}"
    end

    # ── Purge ────────────────────────────────────────────────────────────────
    purge_service = HudReports::PurgeArchivedReportDataService.new(report, dry_run: false, force: true)
    result = purge_service.purge!
    expect(result[:success]).to be(true), "Purge failed: #{result[:errors].inspect}"
    report.reload
    expect(report.purged?).to be true

    # Verify records are gone (paranoid and non-paranoid models alike)
    config.each do |name, entry|
      remaining = entry[:scope].call.count
      expect(remaining).to eq(0),
                           "Expected 0 records after purge for #{name}, found #{remaining}"
    end

    # ── Restore ──────────────────────────────────────────────────────────────
    restore_service = HudReports::RestoreArchivedReportDataService.new(report)
    restore_result = restore_service.restore!
    expect(restore_result[:success]).to be(true), "Restore failed: #{restore_result[:errors].inspect}"
    report.reload
    expect(report.purged?).to be false

    # Verify restored counts match originals
    config.each do |name, entry|
      restored = entry[:scope].call.count
      expect(restored).to eq(before_counts[name]),
                          "Restored count mismatch for #{name}: restored=#{restored}, original=#{before_counts[name]}"
    end

    # Verify sequence reset: creating a new record should not raise PK conflict
    expect do
      report.report_cells.create!(question: 'Verify', cell_name: 'Z99', universe: false)
    end.not_to raise_error
  end

  # Convert a generator fiscal_year string like "FY 2026" to the Ruby module
  # segment used in class names, e.g. "Fy2026".
  def fy_module_name(fiscal_year)
    fiscal_year.gsub(/FY (\d+)/, 'Fy\1')
  end

  # Insert a UniverseMember row bypassing ActiveRecord validations so we do not
  # need a real GrdaWarehouse::Hud::Client row.  belongs_to :client is non-optional
  # on UniverseMember, but the underlying column is nullable.
  def insert_universe_member(report_cell_id:, type:, membership_id:)
    HudReports::UniverseMember.insert(
      { report_cell_id: report_cell_id,
        universe_membership_type: type,
        universe_membership_id: membership_id,
        client_id: nil },
    )
  end

  # ── FY2020 explicit ─────────────────────────────────────────────────────────
  describe 'FY2020 full cycle' do
    let(:report) { create_completed_report(HudSpmReport::Generators::Fy2020::Generator.title) }

    before do
      cell = report.report_cells.create!(question: 'Measure 1', cell_name: 'A1', universe: false)

      # SpmClient requires client_id, data_source_id, and report_instance_id (NOT NULL in DB).
      # Uses acts_as_paranoid so the default scope excludes soft-deleted records.
      client = HudSpmReport::Fy2020::SpmClient.create!(
        report_instance_id: report.id,
        client_id: 1,
        data_source_id: 1,
      )

      insert_universe_member(
        report_cell_id: cell.id,
        type: 'HudSpmReport::Fy2020::SpmClient',
        membership_id: client.id,
      )
    end

    it 'completes archive → purge → restore cycle preserving row counts and PKs' do
      run_archive_purge_restore_cycle(report)
    end
  end

  # ── Current version (FY2026 polymorphic) ────────────────────────────────────
  describe 'current version full cycle' do
    let(:current_gen) { HudSpmReport.current_generator }
    let(:report) { create_completed_report(current_gen.title) }

    before do
      cell = report.report_cells.create!(question: 'Measure 1', cell_name: 'A1', universe: false)

      config_keys = current_gen.archival_csv_config(report).keys
      fy_mod = fy_module_name(current_gen.fiscal_year)

      if config_keys.include?(:spm_enrollments_csv)
        # FY2023+ generators use SpmEnrollment as the primary universe record.
        # SpmEnrollment validates :client and :enrollment presence, so bypass AR
        # validations using insert_all which returns the new row's id.
        enrollment_klass = "HudSpmReport::#{fy_mod}::SpmEnrollment".constantize
        result = enrollment_klass.insert({ report_instance_id: report.id }, returning: [:id])
        enrollment_id = result.first['id']

        insert_universe_member(
          report_cell_id: cell.id,
          type: enrollment_klass.name,
          membership_id: enrollment_id,
        )
      elsif config_keys.include?(:spm_clients_csv)
        # FY2020 fallback path
        client_klass = "HudSpmReport::#{fy_mod}::SpmClient".constantize
        client = client_klass.create!(
          report_instance_id: report.id,
          client_id: 1,
          data_source_id: 1,
        )

        insert_universe_member(
          report_cell_id: cell.id,
          type: client_klass.name,
          membership_id: client.id,
        )
      end
    end

    it 'completes archive → purge → restore cycle with the current SPM generator' do
      run_archive_purge_restore_cycle(report)
    end
  end
end
