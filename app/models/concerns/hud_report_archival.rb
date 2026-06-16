###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudReportArchival
  extend ActiveSupport::Concern

  mattr_accessor :generator_registry
  self.generator_registry = {}

  def self.register_archival_generator(report_name, klass)
    raise NotImplementedError, "#{klass} must implement self.archival_csv_config to register as an archival generator" unless klass.respond_to?(:archival_csv_config)

    generator_registry[report_name] = klass
  end

  # Common archival entries shared by every HUD report driver: the universe_members
  # and report_cells tables that back all report types. Call from each driver's
  # archival_csv_config and merge in driver-specific entries.
  #
  # prefix: short lowercase identifier for this report type (e.g. 'apr', 'spm', 'dq').
  # Used only for human-readable CSV filenames; has no functional effect on restore.
  def self.shared_archival_entries(report_instance, prefix:)
    {
      universe_members_csv: {
        scope: -> { ::HudReports::UniverseMember.where(report_cell_id: report_instance.report_cells.select(:id)) },
        filename: -> { "hud-#{prefix}-#{report_instance.id}-universe-members.csv" },
        delete_order: 1,
      },
      report_cells_csv: {
        scope: -> { report_instance.report_cells },
        filename: -> { "hud-#{prefix}-#{report_instance.id}-cells.csv" },
        delete_order: 99,
      },
    }
  end

  included do
    has_one_attached :report_cells_csv
    has_one_attached :universe_members_csv

    # APR / CAPER / CE-APR
    has_one_attached :apr_clients_csv
    has_one_attached :apr_living_situations_csv
    has_one_attached :apr_ce_assessments_csv
    has_one_attached :apr_ce_events_csv

    # DQ
    has_one_attached :dq_clients_csv
    has_one_attached :dq_living_situations_csv

    # HIC
    has_one_attached :hic_projects_csv
    has_one_attached :hic_project_cocs_csv
    has_one_attached :hic_inventories_csv
    has_one_attached :hic_organizations_csv
    has_one_attached :hic_funders_csv

    # LSA
    has_one_attached :lsa_summary_results_csv

    # PATH
    has_one_attached :path_clients_csv

    # PIT
    has_one_attached :pit_clients_csv

    # SPM
    has_one_attached :spm_clients_csv
    has_one_attached :spm_enrollments_csv
    has_one_attached :spm_enrollment_links_csv
    has_one_attached :spm_episodes_csv
    has_one_attached :spm_returns_csv
    has_one_attached :spm_bed_nights_csv

    scope :purge_eligible, ->(grace_period_days, now = Time.current) do
      sanitized_days = grace_period_days.to_i

      base = where(state: 'Completed').
        where.not(completed_at: nil).
        where("archival_metadata->>'purged_at' IS NULL").
        where("archival_metadata->>'purge_failed_at' IS NULL")

      # Branch 1: an explicit purge_eligible_at was set (e.g. by the rake task)
      by_explicit_date = base.
        where("archival_metadata->>'purge_eligible_at' IS NOT NULL").
        where("(archival_metadata->>'purge_eligible_at')::timestamp <= ?", now)

      # Branch 2: no explicit date — fall back to completed_at + grace period
      by_grace_period = base.
        where("archival_metadata->>'purge_eligible_at' IS NULL").
        where("completed_at + INTERVAL '#{sanitized_days} days' <= ?", now)

      by_explicit_date.or(by_grace_period)
    end
  end

  def archived?
    return false unless archival_metadata&.dig('archived_at').present?

    expected = archival_metadata['expected_files'] || []
    return false if expected.empty?

    expected.all? { |name| send(name).attached? }
  end

  def purged?
    archival_metadata&.dig('purged_at').present?
  end

  def purge_eligible?
    return false if purged?

    purge_eligible_at_str = archival_metadata&.dig('purge_eligible_at')

    return Time.zone.parse(purge_eligible_at_str) <= Time.current if purge_eligible_at_str.present?
    return false unless completed_at.present?

    grace = archival_metadata&.dig('grace_period_days') || Reports.archival_grace_period_days
    (completed_at + grace.to_i.days) <= Time.current
  end

  def archival_status
    return { archived: false } unless archival_metadata&.dig('archived_at').present?

    expected = archival_metadata['expected_files'] || []
    files_status = expected.each_with_object({}) do |name, hash|
      att = send(name)
      hash[name] = { expected: true, attached: att.attached? }
    end

    {
      archived: archived?,
      purged: purged?,
      purge_eligible: purge_eligible?,
      archived_at: archival_metadata['archived_at'],
      purged_at: archival_metadata['purged_at'],
      purge_eligible_at: archival_metadata['purge_eligible_at'],
      grace_period_days: archival_metadata['grace_period_days'],
      expected_file_count: archival_metadata['expected_file_count'],
      expected_files: expected,
      files: files_status,
    }
  end

  def update_archival_metadata(key, value)
    current = archival_metadata || {}
    update_column(:archival_metadata, current.merge(key.to_s => value))
  end

  def archival_generator_klass
    # Prefer the class name stored at archive time — stable across title renames.
    # Fall back to the registry (keyed by report_name/title) for reports archived
    # before this field was introduced, and for pre-archive lookups (e.g., rake task).
    class_name = archival_metadata&.dig('generator_class')
    return class_name.constantize if class_name.present?

    HudReportArchival.generator_registry[report_name]
  end

  def archival_csv_config
    archival_generator_klass&.archival_csv_config(self) || {}
  end

  def archive_and_purge!(force: false)
    unless archived?
      # HudReports::ArchiveReportService and HudReports::PurgeArchivedReportDataService
      # are defined in app/services/hud_reports/ (created alongside this concern).
      service = HudReports::ArchiveReportService.new(self)
      reload
      success = service.archive!
      unless success
        msgs = service.errors.map { |e| e.is_a?(Hash) ? "#{e[:attachment]}: #{e[:error]}" : e.to_s }
        Rails.logger.error("HudReportArchival: Failed to archive report ##{id}. Errors: #{msgs.inspect}")
        return { success: false, errors: ["Failed to archive before purge: #{msgs.join(', ')}"] }
      end
    end

    purge_service = HudReports::PurgeArchivedReportDataService.new(self, dry_run: false, force: force)
    purge_service.purge!
  end
end
