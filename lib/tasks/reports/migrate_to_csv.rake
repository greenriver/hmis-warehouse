###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

namespace :reports do
  namespace :csv do
    desc 'Archive (if needed) and purge database data for reports where grace period has expired'
    task :archive_and_purge_eligible, [:dry_run] => :environment do |_t, args|
      dry_run = ['true', '1'].include?(args[:dry_run])

      puts "Archiving (if needed) and purging database data for eligible reports (grace period expired)#{dry_run ? ' (DRY RUN)' : ''}..."
      puts ''

      # Ensure models are loaded so report types are registered
      Rails.application.eager_load! unless Rails.application.config.eager_load

      now = Time.current
      grace_period_days = Reports.archival_grace_period_days
      archival_types = Rails.application.config.report_archival_types

      if archival_types.empty?
        puts 'No report types configured for archival.'
        next
      end

      # Filter at database level:
      # - Must be one of the configured archival types
      # - Must have completed_at
      # - Must not be purged yet (purged_at is null) and must have purge_eligible_at <= now OR (purge_eligible_at doesn't exist AND completed_at + grace_period_days <= now)
      reports_to_process = SimpleReports::ReportInstance.
        of_types(archival_types).
        completed.
        purge_eligible(grace_period_days, now).
        order(updated_at: :asc)

      puts "Found #{reports_to_process.count} reports eligible for archival and purging (grace period expired)"
      puts ''

      if reports_to_process.empty?
        puts 'No reports eligible for archival and purging at this time.'
        next
      end

      reports_to_process = reports_to_process.limit(20)
      puts "Processing #{reports_to_process.count} reports"

      success_count = 0
      failure_count = 0
      errors = []

      reports_to_process.each do |report|
        if dry_run
          puts "DRY RUN: Would archive and purge report ##{report.id} (#{report.class.name})"
          success_count += 1
        else
          result = report.archive_and_purge!

          if result[:success]
            success_count += 1
            puts "Report ##{report.id} (#{report.class.name}) - Archived and purged:"
            result[:deleted_counts]&.each do |model, count|
              puts "  #{model}: #{count} records"
            end
          else
            failure_count += 1
            error_msg = "Report #{report.class.name} ##{report.id}: #{result[:errors].join(', ')}"
            errors << error_msg
            Rails.logger.error(error_msg)
            Sentry.capture_exception_with_info(
              StandardError.new(error_msg),
              "Failed to archive and purge report #{report.class.name} ##{report.id}",
              {
                report_id: report.id,
                report_class: report.class.name,
                errors: result[:errors],
              },
            )
            puts "Report ##{report.id} - Failed: #{error_msg}"
          end
        end
      rescue StandardError => e
        failure_count += 1
        error_msg = "Error processing report #{report.class.name} ##{report.id}: #{e.message}"
        errors << error_msg
        Rails.logger.error("#{error_msg}\n#{e.backtrace.first(5).join("\n")}")
        Sentry.capture_exception_with_info(
          e,
          "Error processing archival and purge task for report #{report.class.name} ##{report.id}",
          {
            report_id: report.id,
            report_class: report.class.name,
          },
        )
        puts "Report ##{report.id} - Error: #{error_msg}"
      end

      puts ''
      puts "Archive and purge#{dry_run ? ' (DRY RUN)' : ''} complete:"
      puts "  Success: #{success_count}"
      puts "  Failures: #{failure_count}"

      if errors.any?
        puts ''
        puts 'Errors:'
        errors.each do |error|
          puts "  - #{error}"
        end
      end
    end
  end
end
