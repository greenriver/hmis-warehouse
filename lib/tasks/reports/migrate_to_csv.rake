###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

namespace :reports do
  namespace :csv do
    desc 'Migrate existing reports to CSV storage'
    task :migrate, [:report_type, :dry_run, :report_id] => :environment do |_t, args|
      report_type = args[:report_type]
      report_id = args[:report_id]
      dry_run = ['true', '1'].include?(args[:dry_run])

      puts "Starting CSV migration#{dry_run ? ' (DRY RUN)' : ''}..."
      if report_id
        puts "Report ID: #{report_id}"
      else
        puts "Report type: #{report_type || 'all eligible types'}"
      end
      puts ''

      success_count = 0
      failure_count = 0
      errors = []

      # Build scope for reports to migrate
      reports = if report_id
        report = SimpleReports::ReportInstance.find_by(id: report_id)
        unless report
          puts "Error: Report ##{report_id} not found"
          exit 1
        end
        [report]
      else
        scope = SimpleReports::ReportInstance.where.not(completed_at: nil) # Only migrate completed reports
        scope = scope.where(type: report_type) if report_type.present?
        scope.to_a
      end

      reports.each do |report|
        # Skip if already archived and complete
        next if report.archived? && report.archival_complete?

        archive_service = Reports::ArchiveReportService.new(report)
        next unless archive_service.eligible?

        if dry_run
          Rails.logger.info("DRY RUN: Would migrate report #{report.class.name} ##{report.id}")
          puts "DRY RUN: Would migrate report #{report.class.name} ##{report.id}"
          success_count += 1
        elsif archive_service.archive!
          success_count += 1
          Rails.logger.info("Migrated report #{report.class.name} ##{report.id} to CSV")
          puts "Migrated report #{report.class.name} ##{report.id} to CSV"
        else
          failure_count += 1
          error_msg = "Failed to migrate report #{report.class.name} ##{report.id}: #{archive_service.errors.inspect}"
          errors << error_msg
          Rails.logger.error(error_msg)
          puts error_msg
        end
      rescue StandardError => e
        failure_count += 1
        error_msg = "Error migrating report #{report.class.name} ##{report.id}: #{e.message}"
        errors << error_msg
        Rails.logger.error("#{error_msg}\n#{e.backtrace.first(5).join("\n")}")
        puts error_msg
      end

      puts ''
      puts "Migration#{dry_run ? ' (DRY RUN)' : ''} complete:"
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

    desc 'Archive a single report to CSV'
    task :archive, [:report_id] => :environment do |_t, args|
      report_id = args[:report_id]

      unless report_id
        puts 'Error: report_id is required'
        puts 'Usage: rails reports:csv:archive[report_id]'
        exit 1
      end

      report = SimpleReports::ReportInstance.find_by(id: report_id)
      unless report
        puts "Error: Report ##{report_id} not found"
        exit 1
      end

      puts "Archiving report ##{report_id}..."
      puts "Report type: #{report.class.name}"
      puts ''

      service = Reports::ArchiveReportService.new(report)
      unless service.eligible?
        puts "Error: Report type #{report.class.name} is not eligible for archival"
        puts 'Report must include ReportArchival concern and define archival_csv_config'
        exit 1
      end

      if report.archival_complete?
        puts "Warning: Report ##{report_id} is already archived (archival complete)"
        puts 'Use reports:csv:reload to reload data from CSV if needed'
        exit 0
      end

      success = service.archive!

      puts ''
      if success
        if service.errors.any?
          puts 'Archival completed with warnings:'
          service.errors.each do |error|
            puts "  - #{error}"
          end
        else
          puts 'Archival complete!'
        end

        status = report.reload.archival_status
        puts ''
        puts 'Archival status:'
        puts "  Archived at: #{status[:archived_at]}"
        puts "  Expected files: #{status[:expected_file_count]}"
        puts "  Complete: #{status[:complete]}"
        puts "  Purge eligible at: #{status[:purge_eligible_at]}"

        if status[:files].any?
          puts ''
          puts 'Files:'
          status[:files].each do |attachment_name, file_status|
            status_icon = file_status[:attached] ? '✓' : '✗'
            puts "  #{status_icon} #{attachment_name}: #{file_status[:file_count]} file(s)"
          end
        end
      else
        puts 'Archival failed:'
        service.errors.each do |error|
          puts "  - #{error}"
        end
        exit 1
      end
    end

    desc 'Check archival status of reports'
    task :status, [:report_type] => :environment do |_t, args|
      report_type = args[:report_type]

      scope = SimpleReports::ReportInstance.where.not(completed_at: nil)
      scope = scope.where(type: report_type) if report_type.present?

      # Filter to only reports that are eligible for archival
      all_reports = scope.to_a
      eligible_reports = all_reports.select do |report|
        service = Reports::ArchiveReportService.new(report)
        service.eligible?
      end

      total = eligible_reports.count
      archived = eligible_reports.select(&:archived?).count
      complete = eligible_reports.select(&:archival_complete?).count
      incomplete = eligible_reports.select(&:incomplete_archival?).count

      puts "Report CSV Archival Status#{report_type ? " (#{report_type})" : ''}:"
      puts "  Total reports: #{total}"
      puts "  Archived: #{archived}"
      puts "  Complete: #{complete}"
      puts "  Incomplete: #{incomplete}"

      if incomplete > 0
        puts ''
        puts 'Incomplete archival reports:'
        eligible_reports.select(&:incomplete_archival?).each do |report|
          status = report.archival_status
          puts "  Report ##{report.id} (#{report.class.name}):"
          puts "    Expected files: #{status[:expected_file_count]}"
          puts "    Missing files: #{status[:files].reject { |_, f| f[:attached] }.keys.join(', ')}"
        end
      end
    end

    desc 'Purge database data for an archived report'
    task :purge, [:report_id, :dry_run, :force] => :environment do |_t, args|
      report_id = args[:report_id]
      dry_run = ['true', '1'].include?(args[:dry_run])
      force = ['true', '1'].include?(args[:force])

      unless report_id
        puts 'Error: report_id is required'
        puts 'Usage: rails reports:csv:purge[report_id,dry_run,force]'
        puts '  dry_run: true/1 to preview without deleting (optional)'
        puts '  force: true/1 to bypass grace period (optional)'
        exit 1
      end

      report = SimpleReports::ReportInstance.find_by(id: report_id)
      unless report
        puts "Error: Report ##{report_id} not found"
        exit 1
      end

      puts "Purging database data for report ##{report_id}#{dry_run ? ' (DRY RUN)' : ''}#{force ? ' (FORCE - bypassing grace period)' : ''}..."
      puts "Report type: #{report.class.name}"
      puts ''

      service = Reports::PurgeArchivedReportDataService.new(report, dry_run: dry_run, force: force)
      result = service.purge!

      puts ''
      if result[:success]
        if dry_run
          puts 'DRY RUN: Would delete:'
          result[:would_delete]&.each do |model, count|
            puts "  #{model}: #{count} records"
          end
        else
          puts 'Purge complete:'
          result[:deleted_counts]&.each do |model, count|
            puts "  #{model}: #{count} records deleted"
          end
          puts "  Purged at: #{result[:purged_at]}"
        end
      else
        puts 'Purge failed:'
        result[:errors].each do |error|
          puts "  - #{error}"
        end
        exit 1
      end
    end

    desc 'Purge database data for archived reports where grace period has expired'
    task :purge_eligible, [:dry_run] => :environment do |_t, args|
      dry_run = ['true', '1'].include?(args[:dry_run])

      puts "Purging database data for eligible reports (grace period expired)#{dry_run ? ' (DRY RUN)' : ''}..."
      puts ''

      now = Time.current

      # First, filter at database level to narrow down candidates:
      # - Must have completed_at
      # - Must have archival_metadata with archived_at (indicates archival started)
      # - Must not be purged yet (purged_at is null)
      # - Must have purge_eligible_at set and expired
      candidate_scope = SimpleReports::ReportInstance.
        where.not(completed_at: nil).
        where.not(archival_metadata: nil).
        where(Arel.sql("archival_metadata->>'archived_at' IS NOT NULL")).
        where(Arel.sql("archival_metadata->>'purged_at' IS NULL")).
        where(Arel.sql("archival_metadata->>'purge_eligible_at' IS NOT NULL")).
        where(Arel.sql("(archival_metadata->>'purge_eligible_at')::timestamp <= ?"), now)

      # Then check eligibility and archival completeness only on candidates
      reports_to_purge = candidate_scope.select do |report|
        # Check eligibility (includes concern and has config)
        service = Reports::ArchiveReportService.new(report)
        next false unless service.eligible?

        # Check archival completeness
        next false unless report.archival_complete?

        true
      end

      puts "Found #{reports_to_purge.count} reports eligible for purging (grace period expired)"
      puts ''

      if reports_to_purge.empty?
        puts 'No reports eligible for purging at this time.'
        next
      end

      success_count = 0
      failure_count = 0
      errors = []

      reports_to_purge.each do |report|
        service = Reports::PurgeArchivedReportDataService.new(report, dry_run: dry_run, force: false)
        result = service.purge!

        if result[:success]
          success_count += 1
          if dry_run
            puts "DRY RUN: Report ##{report.id} (#{report.class.name}) - Would delete:"
            result[:would_delete]&.each do |model, count|
              puts "  #{model}: #{count} records"
            end
          else
            puts "Report ##{report.id} (#{report.class.name}) - Purged:"
            result[:deleted_counts]&.each do |model, count|
              puts "  #{model}: #{count} records"
            end
          end
        else
          failure_count += 1
          error_msg = "Report ##{report.id}: #{result[:errors].join(', ')}"
          errors << error_msg
          puts "Report ##{report.id} - Failed: #{error_msg}"
        end
      end

      puts ''
      puts "Purge#{dry_run ? ' (DRY RUN)' : ''} complete:"
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

    desc 'Purge database data for all archived reports that have not been purged yet'
    task :purge_all, [:dry_run] => :environment do |_t, args|
      dry_run = ['true', '1'].include?(args[:dry_run])

      puts "Purging database data for all archived reports#{dry_run ? ' (DRY RUN)' : ''}..."
      puts ''

      # First, filter at database level to narrow down candidates:
      # - Must have completed_at
      # - Must have archival_metadata with archived_at (indicates archival started)
      # - Must not be purged yet (purged_at is null)
      candidate_scope = SimpleReports::ReportInstance.
        where.not(completed_at: nil).
        where.not(archival_metadata: nil).
        where(Arel.sql("archival_metadata->>'archived_at' IS NOT NULL")).
        where(Arel.sql("archival_metadata->>'purged_at' IS NULL"))

      # Then check eligibility and archival completeness only on candidates
      reports_to_purge = candidate_scope.select do |report|
        # Check eligibility (includes concern and has config)
        service = Reports::ArchiveReportService.new(report)
        next false unless service.eligible?

        # Check archival completeness
        next false unless report.archival_complete?

        true
      end

      puts "Found #{reports_to_purge.count} reports eligible for purging"
      puts ''

      success_count = 0
      failure_count = 0
      errors = []

      reports_to_purge.each do |report|
        service = Reports::PurgeArchivedReportDataService.new(report, dry_run: dry_run, force: false)
        result = service.purge!

        if result[:success]
          success_count += 1
          if dry_run
            puts "DRY RUN: Report ##{report.id} - Would delete:"
            result[:would_delete]&.each do |model, count|
              puts "  #{model}: #{count} records"
            end
          else
            puts "Report ##{report.id} - Purged:"
            result[:deleted_counts]&.each do |model, count|
              puts "  #{model}: #{count} records"
            end
          end
        else
          failure_count += 1
          error_msg = "Report ##{report.id}: #{result[:errors].join(', ')}"
          errors << error_msg
          puts "Report ##{report.id} - Failed: #{error_msg}"
        end
      end

      puts ''
      puts "Purge#{dry_run ? ' (DRY RUN)' : ''} complete:"
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

    desc 'Reload database data from CSV for an archived report'
    task :reload, [:report_id, :dry_run] => :environment do |_t, args|
      report_id = args[:report_id]
      dry_run = ['true', '1'].include?(args[:dry_run])

      unless report_id
        puts 'Error: report_id is required'
        puts 'Usage: rails reports:csv:reload[report_id,dry_run]'
        exit 1
      end

      report = SimpleReports::ReportInstance.find_by(id: report_id)
      unless report
        puts "Error: Report ##{report_id} not found"
        exit 1
      end

      puts "Reloading database data from CSV for report ##{report_id}#{dry_run ? ' (DRY RUN)' : ''}..."
      puts "Report type: #{report.class.name}"
      puts ''

      service = Reports::ReloadReportFromCsvService.new(report)
      unless service.can_reload?
        puts 'Error: CSV files are not available or archival is incomplete'
        exit 1
      end

      if dry_run
        puts 'DRY RUN: Would reload the following associations:'
        config = report.archival_csv_config
        config.each do |attachment_name, _csv_config|
          puts "  - #{attachment_name}"
        end
        puts ''
        puts 'DRY RUN: No data would be reloaded'
      else
        result = service.reload!

        puts ''
        if result[:success]
          puts 'Reload complete:'
          result[:reloaded_counts]&.each do |attachment_name, count|
            puts "  #{attachment_name}: #{count} records reloaded"
          end
          puts '  Grace period restarted'
        else
          puts 'Reload failed:'
          result[:errors].each do |error|
            puts "  - #{error}"
          end
          exit 1
        end
      end
    end
  end
end
