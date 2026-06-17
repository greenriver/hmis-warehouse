###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

namespace :reports do
  namespace :csv do
    desc 'Archive (if needed) and purge SimpleReports where grace period has expired'
    task :archive_and_purge_simple_reports, [:dry_run] => :environment do |_t, args|
      dry_run = ['true', '1'].include?(args[:dry_run])

      puts "Archiving (if needed) and purging database data for eligible SimpleReports (grace period expired)#{dry_run ? ' (DRY RUN)' : ''}..."
      puts ''

      # Driver model paths are on autoload_paths only (not eager_load_paths), so
      # eager_load! does not load them. We scan only SimpleReport models that include
      # ReportArchival, which is where report_archival_types registrations live.
      # Matches: `include ReportArchival` — the line present in each SimpleReport model
      # that registers it with Rails.application.config.report_archival_types.
      Dir[Rails.root.join('drivers', '*', 'app', 'models', '**', '*.rb')].sort.each do |f|
        require f if File.read(f).include?('include ReportArchival')
      end

      now = Time.current
      grace_period_days = Reports.archival_grace_period_days
      archival_types = Rails.application.config.report_archival_types

      if archival_types.empty?
        puts 'No SimpleReport types configured for archival.'
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

      puts "Found #{reports_to_process.count} SimpleReports eligible for archival and purging (grace period expired)"
      puts ''

      if reports_to_process.empty?
        puts 'No SimpleReports eligible for archival and purging at this time.'
      else
        reports_to_process = reports_to_process.limit(20)
        puts "Processing #{reports_to_process.count} reports"

        success_count = 0
        failure_count = 0
        errors = []

        reports_to_process.each do |report|
          if dry_run
            puts "DRY RUN: Would archive and purge SimpleReport ##{report.id} (#{report.class.name})"
            success_count += 1
          else
            result = report.archive_and_purge!

            if result[:success]
              success_count += 1
              puts "SimpleReport ##{report.id} (#{report.class.name}) - Archived and purged:"
              result[:deleted_counts]&.each do |model, count|
                puts "  #{model}: #{count} records"
              end
            else
              failure_count += 1
              error_msg = "SimpleReport #{report.class.name} ##{report.id}: #{result[:errors].join(', ')}"
              errors << error_msg
              Rails.logger.error(error_msg)
              report.update_archival_metadata('purge_failed_at', Time.current.iso8601)
              report.update_archival_metadata('purge_failure_reason', result[:errors].join(', '))
              Sentry.capture_exception_with_info(
                StandardError.new(error_msg),
                "Failed to archive and purge SimpleReport #{report.class.name} ##{report.id}",
                {
                  report_id: report.id,
                  report_class: report.class.name,
                  errors: result[:errors],
                },
              )
              puts "SimpleReport ##{report.id} - Failed: #{error_msg}"
            end
          end
        rescue StandardError => e
          failure_count += 1
          error_msg = "Error processing SimpleReport ##{report.id}: #{e.message}"
          errors << error_msg
          Rails.logger.error("#{error_msg}\n#{e.backtrace.first(5).join("\n")}")
          Sentry.capture_exception_with_info(
            e,
            "Error processing archival and purge task for SimpleReport ##{report.id}",
            {
              report_id: report.id,
              report_class: report.class.name,
            },
          )
          puts "SimpleReport ##{report.id} - Error: #{error_msg}"
        ensure
          GC.start # release report objects between iterations to reduce peak memory
        end

        puts ''
        puts "SimpleReports archive and purge#{dry_run ? ' (DRY RUN)' : ''} complete:"
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

    desc 'Archive (if needed) and purge HUD Reports where grace period has expired'
    task :archive_and_purge_hud_reports, [:dry_run] => :environment do |_t, args|
      dry_run = ['true', '1'].include?(args[:dry_run])

      puts "Archiving and purging eligible HUD Reports#{dry_run ? ' (DRY RUN)' : ''}..."
      puts ''

      # Driver model paths are on autoload_paths only (not eager_load_paths), so
      # eager_load! does not load them. We load HUD generator files that include a
      # driver-specific Archival concern, which is where generator_registry registrations live.
      # Matches: `include HudApr::Archival`, `include HudLsa::Archival`, etc. —
      # the line present in each HUD generator class that registers it with
      # HudReportArchival.generator_registry via the concern's included do block.
      Dir[Rails.root.join('drivers', '*', 'app', 'models', '**', '*.rb')].sort.each do |f|
        require f if File.read(f).match?(/include \S+::Archival/)
      end

      now = Time.current
      grace_period_days = Reports.archival_grace_period_days
      registered_names = HudReportArchival.generator_registry.keys

      if registered_names.empty?
        puts 'No HUD report types registered for archival.'
        next
      end

      # Filter at database level:
      # - Must be one of the configured archival types
      # - Must have completed_at
      # - Must not be purged yet (purged_at is null) and must have purge_eligible_at <= now OR (purge_eligible_at doesn't exist AND completed_at + grace_period_days <= now)
      reports_to_process = HudReports::ReportInstance.
        where(report_name: registered_names).
        purge_eligible(grace_period_days, now).
        order(completed_at: :asc)

      success_count = 0
      failure_count = 0
      errors = []

      puts "Found #{reports_to_process.count} HUD Reports eligible for archival and purging (grace period expired)"
      puts ''

      if reports_to_process.empty?
        puts 'No HUD Reports eligible for archival and purging at this time.'
      else
        reports_to_process = reports_to_process.limit(20)
        puts "Processing #{reports_to_process.count} reports"

        reports_to_process.each do |report|
          if dry_run
            puts "DRY RUN: Would archive and purge HUD Report ##{report.id} (#{report.report_name})"
            success_count += 1
          else
            result = report.archive_and_purge!

            if result[:success]
              success_count += 1
              puts "HUD Report ##{report.id} (#{report.report_name}) - Archived and purged:"
              result[:deleted_counts]&.each do |model, count|
                puts "  #{model}: #{count} records"
              end
            else
              failure_count += 1
              error_msg = "HUD Report #{report.report_name} ##{report.id}: #{result[:errors].join(', ')}"
              errors << error_msg
              Rails.logger.error(error_msg)
              report.update_archival_metadata('purge_failed_at', Time.current.iso8601)
              report.update_archival_metadata('purge_failure_reason', result[:errors].join(', '))
              Sentry.capture_exception_with_info(
                StandardError.new(error_msg),
                "Failed to archive and purge HUD Report #{report.report_name} ##{report.id}",
                {
                  report_id: report.id,
                  report_name: report.report_name,
                  errors: result[:errors],
                },
              )
              puts "HUD Report ##{report.id} - Failed: #{error_msg}"
            end
          end
        rescue StandardError => e
          failure_count += 1
          error_msg = "Error processing HUD Report #{report.report_name} ##{report.id}: #{e.message}"
          errors << error_msg
          Rails.logger.error("#{error_msg}\n#{e.backtrace.first(5).join("\n")}")
          Sentry.capture_exception_with_info(
            e,
            "Error processing archival and purge task for HUD Report ##{report.id}",
            {
              report_id: report.id,
              report_name: report.report_name,
            },
          )
          puts "HUD Report ##{report.id} - Error: #{error_msg}"
        ensure
          GC.start # release report objects between iterations to reduce peak memory
        end

        puts ''
        puts "HUD Reports archive and purge#{dry_run ? ' (DRY RUN)' : ''} complete:"
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

    desc 'Archive (if needed) and purge database data for reports where grace period has expired'
    task :archive_and_purge_eligible, [:dry_run] => :environment do |_t, args|
      dry_run = args[:dry_run]
      Rake::Task['reports:csv:archive_and_purge_simple_reports'].invoke(dry_run)
      Rake::Task['reports:csv:archive_and_purge_hud_reports'].invoke(dry_run)
    end
  end
end
