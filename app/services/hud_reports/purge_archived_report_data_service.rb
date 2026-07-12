###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'report_csv_reader'

module HudReports
  # Safely purges database records for an archived HudReports::ReportInstance.
  # Safety checks mirror Reports::PurgeArchivedReportDataService (SimpleReports).
  # Deletion order follows the delete_order key in archival_csv_config (ascending).
  # After CSV-backed records, purges household_contexts and checkpoints.
  #
  # Atomicity: all deletions and the purged_at timestamp are written inside a
  # single transaction. A mid-run failure (constraint violation, network blip)
  # rolls back every deletion, leaving the report in its pre-purge archived state
  # so the operation can be safely retried.
  class PurgeArchivedReportDataService
    attr_reader :report, :dry_run, :force, :errors

    def initialize(report, dry_run: false, force: false)
      @report = report
      @dry_run = dry_run
      @force = force
      @errors = []
    end

    def purge!
      return { success: false, errors: ['Report not present'] } unless report.present?
      return { success: false, errors: @errors } unless safety_checks_passed?

      if dry_run
        Rails.logger.info("DRY RUN: Would purge database data for HudReports::ReportInstance ##{report.id}")
        return { success: true, dry_run: true, would_delete: deletion_summary }
      end

      deleted_counts = nil
      report.class.transaction do
        deleted_counts = delete_report_data
        mark_purged
      end

      Rails.logger.info("HudReports::PurgeArchivedReportDataService: Purged report ##{report.id}: #{deleted_counts.inspect}")
      { success: true, deleted_counts: deleted_counts, purged_at: Time.current }
    rescue StandardError => e
      @errors << e.message
      Rails.logger.error("HudReports::PurgeArchivedReportDataService: Transaction rolled back for report ##{report.id}: #{e.message}")
      { success: false, errors: @errors }
    end

    private

    def expected_files
      @expected_files ||= report.archival_metadata&.dig('expected_files') || []
    end

    def safety_checks_passed?
      @errors = []

      unless report.state == 'Completed' && report.completed_at.present?
        @errors << 'Report has not been completed'
        return false
      end

      unless report.archived?
        @errors << 'Report has not been archived or archival is incomplete'
        return false
      end

      unless csv_files_accessible?
        @errors << 'One or more CSV files are not accessible'
        return false
      end

      unless csv_data_integrity_verified?
        @errors << 'CSV data integrity check failed (row counts do not match)'
        return false
      end

      if report.purged?
        @errors << 'Report data has already been purged'
        return false
      end

      unless force || grace_period_expired?
        purge_at = report.archival_metadata&.dig('purge_eligible_at')
        days_left = purge_at ? ((Time.zone.parse(purge_at) - Time.current) / 1.day).ceil : '?'
        @errors << "Grace period has not expired (#{days_left} day(s) remaining). Use force: true to bypass."
        return false
      end

      true
    end

    def csv_files_accessible?
      return false if expected_files.empty?

      expected_files.all? { |name| report.send(name).attached? }
    end

    def csv_data_integrity_verified?
      config = report.archival_csv_config
      return true if expected_files.empty?

      expected_files.all? do |name|
        entry = config[name.to_sym]
        next true unless entry&.key?(:scope)

        csv_count = ReportCsvReader.new(report, name.to_sym).count
        db_count = entry[:scope].call.count

        if csv_count != db_count
          Rails.logger.warn(
            "HudReports purge integrity fail: #{name} CSV=#{csv_count} DB=#{db_count} report ##{report.id}",
          )
          next false
        end

        true
      end
    end

    def grace_period_expired?
      purge_at_str = report.archival_metadata&.dig('purge_eligible_at')
      return Time.zone.parse(purge_at_str) <= Time.current if purge_at_str.present?

      return false unless report.completed_at.present?

      grace = report.archival_metadata&.dig('grace_period_days') || Reports.archival_grace_period_days
      (report.completed_at + grace.to_i.days) <= Time.current
    end

    def sorted_config
      report.archival_csv_config.sort_by { |_k, v| v[:delete_order] || 0 }
    end

    def delete_report_data
      counts = {}

      sorted_config.each do |name, entry|
        next unless entry[:scope]

        relation = entry[:scope].call
        counts[name] = hard_delete(relation)
      end

      counts[:household_contexts] = hard_delete(report.household_contexts)
      counts[:checkpoints] = report.checkpoints.destroy_all.size

      counts
    end

    # Permanently removes rows from the database, bypassing acts_as_paranoid soft-delete.
    # Data is already safely archived to CSV, so hard deletion is wanted here.
    # For paranoid models, include soft-deleted rows so records soft-deleted during
    # report retries (via reset_question) are fully removed — not just the live ones.
    #
    # Uses in_batches with a subquery DELETE to avoid loading all IDs into Ruby memory,
    # which matters for large tables like universe_members and report_cells.
    def hard_delete(relation)
      model_class = relation.klass
      table = model_class.quoted_table_name
      scoped = model_class.respond_to?(:with_deleted) ? relation.with_deleted : relation
      deleted_count = 0

      scoped.unscope(:order).in_batches(of: 1_000, load: false) do |batch|
        subquery_sql = batch.select(:id).to_sql
        sql = ActiveRecord::Base.sanitize_sql_array(["DELETE FROM #{table} WHERE id IN (#{subquery_sql})"])
        deleted_count += model_class.connection.execute(sql).cmd_tuples
      end

      deleted_count
    end

    def deletion_summary
      summary = report.archival_csv_config.each_with_object({}) do |(name, entry), hash|
        next unless entry[:scope]

        hash[name] = entry[:scope].call.count
      end
      summary[:household_contexts] = report.household_contexts.count
      summary[:checkpoints] = report.checkpoints.count
      summary
    end

    def mark_purged
      current = report.archival_metadata || {}
      report.update_column(:archival_metadata, current.merge('purged_at' => Time.current.iso8601))
    end
  end
end
