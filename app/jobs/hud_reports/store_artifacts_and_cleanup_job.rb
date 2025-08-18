###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Background job to store HUD report artifacts in S3 and immediately cleanup RDS data
# This job runs after a report is completed to archive intermediate data and free up RDS space
module HudReports
  class StoreArtifactsAndCleanupJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(report_id)
      report = HudReports::ReportInstance.find(report_id)

      Rails.logger.info "Processing report #{report_id} for S3 storage and RDS cleanup"

      begin
        # Step 1: Store artifacts to S3
        store_artifacts_to_s3(report)

        # Step 2: Update report status (mark as artifacts stored)
        update_report_status(report)

        # Step 3: Clean up RDS data
        cleanup_rds_data(report)

        Rails.logger.info "Successfully processed report #{report_id}: stored to S3 and cleaned RDS"
      end
    end

    private

    def store_artifacts_to_s3(report)
      Rails.logger.info "Storing artifacts to S3 for report #{report.id}"

      service = HudReports::FileArtifactService.new(report)
      service.store_artifacts!

      Rails.logger.info "Successfully stored artifacts to S3 for report #{report.id}"
    end

    def cleanup_rds_data(report)
      Rails.logger.info "Cleaning up RDS data for report #{report.id}"

      # Clean up universe members
      cleanup_universe_members(report)

      # Clean up report-specific client tables
      cleanup_report_client_tables(report)

      Rails.logger.info "Successfully cleaned up RDS data for report #{report.id}"
    end

    def cleanup_universe_members(report)
      cell_ids = report.report_cells.pluck(:id)

      return unless cell_ids.any?

      deleted_count = HudReports::UniverseMember.where(report_cell_id: cell_ids).delete_all
      Rails.logger.info "Deleted #{deleted_count} universe members for report #{report.id}"
    end

    def cleanup_report_client_tables(report)
      # We need to leave SpmEnrollments in the database. They are used to build other universe members.
      cleanup_classes = report.associated_scope_classes - [HudSpmReport::Fy2023::SpmEnrollment, HudSpmReport::Fy2024::SpmEnrollment, HudSpmReport::Fy2026::SpmEnrollment]
      # Handle the special cases first in case they have a dependency on other tables
      special_cleanup_classes = cleanup_classes.
        reject { |c| c.column_names.include?('report_instance_id') }

      special_cleanup_classes.each do |table_class|
        handle_special_cleanup(table_class, report)
      end

      # Clean up the tables that have a report_instance_id column
      (cleanup_classes - special_cleanup_classes).each do |table_class|
        deleted_count = table_class.where(report_instance_id: report.id).delete_all
        Rails.logger.info "Deleted #{deleted_count} records from #{table_class.table_name} for report #{report.id}"
      end
    end

    def update_report_status(report)
      # Update timestamp to track the process
      report.update_columns(
        artifacts_stored_at: Time.current,
      )

      Rails.logger.info "Updated status for report #{report.id}"
    end

    def handle_special_cleanup(table_class, report)
      case table_class.name
      when /^HudSpmReport::Fy\d{4}::Episode$/
        # Episode doesn't have report_instance_id, so we need to join through enrollments
        deleted_count = table_class.joins(enrollments: :report_instance).
          where(hud_report_spm_enrollments: { report_instance_id: report.id }).
          delete_all
        Rails.logger.info "Deleted #{deleted_count} records from #{table_class.table_name} for report #{report.id}"
      when /^HudDataQualityReport::Fy\d{4}::DqLivingSituation$/
        # DqLivingSituation belongs to DqClient, which has report_instance_id
        deleted_count = table_class.joins(:dq_client).
          where(hud_report_dq_clients: { report_instance_id: report.id }).
          delete_all
        Rails.logger.info "Deleted #{deleted_count} records from #{table_class.table_name} for report #{report.id}"
      when /^HudApr::Fy\d{4}::AprLivingSituation$/
        # AprLivingSituation belongs to AprClient, which has report_instance_id
        deleted_count = table_class.joins(:apr_client).
          where(hud_report_apr_clients: { report_instance_id: report.id }).
          delete_all
        Rails.logger.info "Deleted #{deleted_count} records from #{table_class.table_name} for report #{report.id}"
      when /^HudApr::Fy\d{4}::CeAssessment$/
        # CeAssessment belongs to AprClient, which has report_instance_id
        deleted_count = table_class.joins(:apr_client).
          where(hud_report_apr_clients: { report_instance_id: report.id }).
          delete_all
        Rails.logger.info "Deleted #{deleted_count} records from #{table_class.table_name} for report #{report.id}"
      when /^HudApr::Fy\d{4}::CeEvent$/
        # CeEvent belongs to AprClient, which has report_instance_id
        deleted_count = table_class.joins(:apr_client).
          where(hud_report_apr_clients: { report_instance_id: report.id }).
          delete_all
        Rails.logger.info "Deleted #{deleted_count} records from #{table_class.table_name} for report #{report.id}"
      else
        Rails.logger.info "Skipping #{table_class.table_name} - no report_instance_id column and no special handling for report #{report.id}"
      end
    end

    def fallback_cleanup(report)
      # This is a fallback for reports that don't have a generator class or don't have a report version
      # It will clean up all tables that inherit from HudReports::ReportClientBase.
      # Only records with the correct report_instance_id will be removed, so most of these calls will be
      # deleting 0 rows.
      ::HudReports::ReportClientBase.descendants.each do |table_class|
        if table_class.column_names.include?('report_instance_id')
          deleted_count = table_class.where(report_instance_id: report.id).delete_all
          Rails.logger.info "Deleted #{deleted_count} records from #{table_class.table_name} for report #{report.id}"
        end
      end
    end
  end
end
