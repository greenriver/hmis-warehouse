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
      report_version = report.options&.dig('report_version')&.to_sym

      if report_version
        # Find the generator class from the config using the report name
        generator_class = generator_class(report.report_name, report_version)

        if generator_class
          # Get the client classes for this specific generator
          client_classes = client_classes_for_generator(generator_class)

          client_classes.each do |table_class|
            if table_class.column_names.include?('report_instance_id')
              deleted_count = table_class.where(report_instance_id: report.id).delete_all
              Rails.logger.info "Deleted #{deleted_count} records from #{table_class.table_name} for report #{report.id}"
            else
              # Handle special cases like Episode which doesn't have report_instance_id
              handle_special_cleanup(table_class, report)
            end
          end
        else
          Rails.logger.info "Could not determine generator class for report #{report.id}, using fallback cleanup"
          fallback_cleanup(report)
        end
      else
        Rails.logger.info "Could not determine report version for report #{report.id}, using fallback cleanup"
        fallback_cleanup(report)
      end
    end

    def update_report_status(report)
      # Update timestamp to track the process
      report.update_columns(
        artifacts_stored_at: Time.current,
      )

      Rails.logger.info "Updated status for report #{report.id}"
    end

    def generator_class(report_name, report_version)
      controller_class = case report_name
      when /Annual Performance Report/
        HudApr::AprsController
      when /Consolidated Annual Performance and Evaluation Report/
        HudApr::CapersController
      when /Coordinated Entry Annual Performance Report/
        HudApr::CeAprsController
      when /System Performance Measures/
        HudSpmReport::SpmsController
      when /Point in Time Count/
        HudPit::PitsController
      when /Annual PATH Report/
        HudPathReport::PathsController
      when /HOPWA CAPER/
        HopwaCaper::ReportsController
      when /HMIS Data Quality Report/
        if [:fy2020, :fy2022].include?(report_version)
          HudDataQualityReport::DqsController
        else
          HudApr::DqsController
        end
      end
      return unless controller_class

      # Create a temporary instance to access the possible_generator_classes method
      controller = controller_class.new
      controller.send(:possible_generator_classes)[report_version]
    end

    def handle_special_cleanup(table_class, report)
      case table_class.name
      when /^HudSpmReport::Fy\d{4}::Episode$/
        # Episode doesn't have report_instance_id, so we need to join through enrollments
        deleted_count = table_class.joins(enrollments: :report_instance).
          where(hud_report_spm_enrollments: { report_instance_id: report.id }).
          delete_all
        Rails.logger.info "Deleted #{deleted_count} records from #{table_class.table_name} for report #{report.id}"
      else
        Rails.logger.info "Skipping #{table_class.table_name} - no report_instance_id column and no special handling for report #{report.id}"
      end
    end

    def client_classes_for_generator(generator_class)
      # Get all client classes by calling client_class for each question
      if generator_class.respond_to?(:questions) && generator_class.respond_to?(:client_class)
        # Get all unique client classes from all questions
        generator_class.questions.keys.map do |question|
          generator_class.client_class(question)
        end.uniq
      elsif generator_class.respond_to?(:table_classes)
        # Fallback to table_classes if client_class is not available
        generator_class.table_classes
      else
        # Look for all descendants of HudReports::ReportClientBase
        # This will include all classes storing report data, but we are going to be
        # filtering this to only look for instances with the correct report_instance_id
        # so only recrods part of this report will be removed.
        ::HudReports::ReportClientBase.descendants
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
