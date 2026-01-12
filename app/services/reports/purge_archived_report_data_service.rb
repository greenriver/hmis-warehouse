###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'report_csv_reader'
require_relative 'archive_report_service'

module Reports
  class PurgeArchivedReportDataService
    attr_reader :report, :errors, :dry_run, :force

    def initialize(report, dry_run: false, force: false)
      @report = report
      @dry_run = dry_run
      @force = force
      @errors = []
    end

    def purge!
      return { success: false, errors: ['Report not found'] } unless report.present?

      # Safety checks
      unless safety_checks_passed?
        return {
          success: false,
          errors: @errors,
        }
      end

      if dry_run
        Rails.logger.info("DRY RUN: Would purge database data for report #{report.class.name} ##{report.id}")
        return {
          success: true,
          dry_run: true,
          would_delete: deletion_summary,
        }
      end

      # Perform deletion
      deleted_counts = delete_report_data
      update_purged_metadata

      Rails.logger.info("Purged database data for report #{report.class.name} ##{report.id}: #{deleted_counts.inspect}")

      {
        success: true,
        deleted_counts: deleted_counts,
        purged_at: Time.current,
      }
    end

    private

    def expected_files
      @expected_files ||= report.archival_metadata&.dig('expected_files') || []
    end

    def safety_checks_passed?
      @errors = []

      # Check 1: Report must be completed
      unless report.completed_at.present?
        @errors << 'Report has not been completed'
        return false
      end

      # Check 2: Archival must be complete (CSV files exist)
      unless report.archived?
        @errors << 'Report has not been archived or archival is not complete'
        return false
      end

      # Check 3: CSV files must be accessible
      unless csv_files_accessible?
        @errors << 'One or more CSV files are not accessible'
        return false
      end

      # Check 4: CSV data integrity (row counts match)
      unless csv_data_integrity_verified?
        @errors << 'CSV data integrity check failed (row counts do not match database)'
        return false
      end

      # Check 5: Already purged
      if already_purged?
        @errors << 'Report data has already been purged'
        return false
      end

      # Check 6: Grace period must have expired (unless force is true)
      unless force || grace_period_expired?
        purge_eligible_at_str = report.archival_metadata&.dig('purge_eligible_at')
        if purge_eligible_at_str
          purge_eligible_at = Time.parse(purge_eligible_at_str)
          days_remaining = ((purge_eligible_at - Time.current) / 1.day).ceil
          @errors << "Grace period has not expired. Data will be eligible for purging in #{days_remaining} day(s) (on #{purge_eligible_at.strftime('%Y-%m-%d')}). Use force: true to bypass."
        else
          @errors << 'Grace period has not expired (purge_eligible_at not set). Use force: true to bypass.'
        end
        return false
      end

      true
    end

    def csv_files_accessible?
      # Check only files that were expected to be archived (from metadata)
      return false if expected_files.empty?

      # Reload report to ensure attachments are fresh
      report.reload unless report.new_record?

      expected_files.all? do |attachment_name|
        attachment = report.send(attachment_name)
        # Check if attachment is attached (attached? already verifies blobs exist)
        attachment.attached?
      end
    end

    def csv_data_integrity_verified?
      config = report.archival_csv_config
      # Only check CSVs that were actually archived (from expected_files)
      return true if expected_files.empty?

      expected_files.all? do |attachment_name|
        csv_config = config[attachment_name.to_sym]
        next true unless csv_config # Skip if not in config (shouldn't happen, but be safe)

        # Get association name for integrity check
        association_name = csv_config[:association]
        unless association_name
          Rails.logger.info("Skipping integrity check for CSV #{attachment_name} without association")
          next true
        end

        # Get CSV row count
        csv_count = csv_row_count(attachment_name.to_sym)

        # Get database count
        db_count = database_row_count(csv_config)

        # Counts must match exactly
        if csv_count != db_count
          Rails.logger.warn(
            "CSV integrity check failed: #{attachment_name} - CSV: #{csv_count}, DB: #{db_count} " \
            "for report ##{report.id}",
          )
          return false
        end

        true
      end
    end

    def csv_row_count(attachment_name)
      # Ensure attachment_name is a symbol
      attachment_name = attachment_name.to_sym if attachment_name.is_a?(String)
      attachment = report.send(attachment_name)
      return 0 unless attachment.attached?

      # Use ReportCsvReader to count rows
      reader = ReportCsvReader.new(report, attachment_name)
      reader.all.count
    end

    def database_row_count(csv_config)
      # Use association to count database rows
      association_name = csv_config[:association]
      return 0 unless association_name

      association = report.send(association_name)
      association.count
    end

    def already_purged?
      report.archival_metadata&.dig('purged_at').present?
    end

    def grace_period_expired?
      # Use purge_eligible_at from metadata if present
      purge_eligible_at_str = report.archival_metadata&.dig('purge_eligible_at')
      if purge_eligible_at_str
        purge_eligible_at = Time.parse(purge_eligible_at_str)
        return purge_eligible_at <= Time.current
      end

      # Otherwise calculate from completed_at + grace_period_days
      # This will cover reports that were created before this metadata was added
      return false unless report.completed_at.present?

      grace_period_days = report.archival_metadata&.dig('grace_period_days') || Reports.archival_grace_period_days
      calculated_purge_eligible_at = report.completed_at + grace_period_days.days
      calculated_purge_eligible_at <= Time.current
    end

    def delete_report_data
      counts = {}
      config = report.archival_csv_config
      return counts if config.empty?

      # Collect all associations to purge, prioritizing order for foreign key dependencies
      purge_associations = {}

      config.each do |attachment_name, csv_config|
        # Use association to determine what to purge
        association_name = csv_config[:association]
        next unless association_name

        purge_associations[attachment_name] = association_name
      end

      # Delete associations in reverse order to handle foreign key dependencies
      # (child records first, then parent records)
      purge_associations.reverse_each do |_attachment_name, association_name|
        counts[association_name] = report.send(association_name).delete_all
      end

      counts
    end

    def deletion_summary
      counts = {}
      config = report.archival_csv_config
      return counts if config.empty?

      config.each do |_attachment_name, csv_config|
        association_name = csv_config[:association]
        next unless association_name

        counts[association_name] = report.send(association_name).count
      end

      counts
    end

    def update_purged_metadata
      current_metadata = report.archival_metadata || {}
      report.update_column(
        :archival_metadata,
        current_metadata.merge(
          'purged_at' => Time.current.iso8601,
        ),
      )
    end
  end
end
