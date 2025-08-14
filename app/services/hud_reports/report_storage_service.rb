###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Service for processing of HUD reports: store to S3 and cleanup RDS
# This service processes reports after completion to maximize RDS space savings
module HudReports
  class ReportStorageService
    include ActionView::Helpers::DateHelper

    # Find reports that need processing (completed but not yet stored to S3)
    def reports_needing_processing
      HudReports::ReportInstance.
        where.not(completed_at: nil).
        where(artifacts_stored_at: nil).
        order(:completed_at)
    end

    # Process a specific report
    def process_report(report_id)
      Rails.logger.info "Processing report #{report_id} for S3 storage and RDS cleanup"

      HudReports::StoreArtifactsAndCleanupJob.perform_now(report_id)
      Rails.logger.info "Successfully processed report #{report_id}"
    end

    # Process all reports that need processing
    def process_all_reports(batch_size: 10, dry_run: false)
      reports = reports_needing_processing
      total_count = reports.count

      Rails.logger.info "Found #{total_count} reports needing processing"

      if dry_run
        Rails.logger.info "DRY RUN: Would process #{total_count} reports"
        return { processed: 0, dry_run: true }
      end

      processed = 0

      reports.find_in_batches(batch_size: batch_size) do |batch|
        batch.each do |report|
          process_report(report.id)
          processed += 1
        end
      end

      Rails.logger.info "Processing completed: #{processed} processed"
      { processed: processed, dry_run: false }
    end
  end
end
