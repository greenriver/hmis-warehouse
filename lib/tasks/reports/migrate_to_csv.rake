###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

namespace :reports do
  namespace :csv do
    desc 'Archive (if needed) and purge SimpleReports where grace period has expired'
    task :archive_and_purge_simple_reports, [:dry_run] => :environment do |_t, args|
      dry_run = ['true', '1'].include?(args[:dry_run])

      puts "Enqueueing archival and purge jobs for eligible SimpleReports (grace period expired)#{dry_run ? ' (DRY RUN)' : ''}..."
      puts ''

      # Ensure models are loaded so report types are registered
      Rails.application.eager_load! unless Rails.application.config.eager_load

      now = Time.current
      grace_period_days = Reports.archival_grace_period_days
      archival_types = Rails.application.config.report_archival_types

      if archival_types.empty?
        puts 'No SimpleReport types configured for archival.'
        next
      end

      eligible_scope = SimpleReports::ReportInstance.
        of_types(archival_types).
        completed.
        purge_eligible(grace_period_days, now).
        order(updated_at: :asc)

      total_count = eligible_scope.count
      reports_to_process = eligible_scope.limit(20)

      puts "Found #{total_count} SimpleReports eligible for archival and purging (grace period expired)"
      puts ''

      if total_count.zero?
        puts 'No SimpleReports eligible for archival and purging at this time.'
      else
        enqueued = 0
        reports_to_process.each do |report|
          if dry_run
            puts "DRY RUN: Would enqueue archival for SimpleReport ##{report.id} (#{report.class.name})"
          else
            Reports::ArchiveAndPurgeReportJob.perform_later(
              report_class: report.class.name,
              report_id: report.id,
            )
            puts "Enqueued SimpleReport ##{report.id} (#{report.class.name})"
            enqueued += 1
          end
        end

        puts ''
        puts "SimpleReports#{dry_run ? ' (DRY RUN)' : ''}: #{dry_run ? 'would enqueue' : 'enqueued'} #{dry_run ? reports_to_process.size : enqueued} jobs"
      end
    end

    desc 'Archive (if needed) and purge HUD Reports where grace period has expired'
    task :archive_and_purge_hud_reports, [:dry_run] => :environment do |_t, args|
      dry_run = ['true', '1'].include?(args[:dry_run])

      puts "Enqueueing archival and purge jobs for eligible HUD Reports#{dry_run ? ' (DRY RUN)' : ''}..."
      puts ''

      # Ensure models are loaded so report types are registered
      Rails.application.eager_load! unless Rails.application.config.eager_load

      now = Time.current
      grace_period_days = Reports.archival_grace_period_days
      registered_names = HudReportArchival.generator_registry.keys

      if registered_names.empty?
        puts 'No HUD report types registered for archival.'
        next
      end

      eligible_scope = HudReports::ReportInstance.
        where(report_name: registered_names).
        purge_eligible(grace_period_days, now).
        order(completed_at: :asc)

      total_count = eligible_scope.count
      reports_to_process = eligible_scope.limit(20)

      puts "Found #{total_count} HUD Reports eligible for archival and purging (grace period expired)"
      puts ''

      if total_count.zero?
        puts 'No HUD Reports eligible for archival and purging at this time.'
      else
        enqueued = 0
        reports_to_process.each do |report|
          if dry_run
            puts "DRY RUN: Would enqueue archival for HUD Report ##{report.id} (#{report.report_name})"
          else
            Reports::ArchiveAndPurgeReportJob.perform_later(
              report_class: report.class.name,
              report_id: report.id,
            )
            puts "Enqueued HUD Report ##{report.id} (#{report.report_name})"
            enqueued += 1
          end
        end

        puts ''
        puts "HUD Reports#{dry_run ? ' (DRY RUN)' : ''}: #{dry_run ? 'would enqueue' : 'enqueued'} #{dry_run ? reports_to_process.size : enqueued} jobs"
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
