# frozen_string_literal: true

desc 'expose log processor job for cron-job'
task process_activity_logs: [:environment] do
  Hmis::ActivityLogProcessorJob.perform_now
end

namespace :activity_logs do
  # CLIENT=tenant1 rails driver:hmis:activity_logs:correlate_active_storage[/host/cloud-watch-request-logs.csv]
  desc 'Correlate Active Storage access logs with Hmis::ActivityLog entries'
  task :correlate_active_storage, [:csv_path, :tolerance_seconds] => :environment do |_task, args|
    require_relative './activity_logs'
    csv_path = args[:csv_path]
    abort 'Provide CSV path: rake hmis:activity_logs:correlate_active_storage[/absolute/path/to/file.csv]' unless csv_path.present?

    tenant = ENV['CLIENT'].presence
    abort 'Set ENV["CLIENT"] to filter logs for a specific tenant' unless tenant

    abort "CSV file not found: #{csv_path}" unless File.exist?(csv_path)

    tolerance_seconds = args[:tolerance_seconds] || 60
    correlator = Hmis::ActivityLogs::Correlator.new(
      csv_path: csv_path,
      tenant: tenant,
      tolerance_seconds: tolerance_seconds,
    )
    correlator.run

    puts '=' * 80
    puts "Analysis Results for tenant: #{tenant}"
    puts '=' * 80
    puts "Total considered (302 redirects):  #{correlator.total_considered}"
    puts "Matched with activity log:         #{correlator.matched}"
    puts "Unmatched (potential unauthorized): #{correlator.unmatched_rows.size}"
    puts "Invalid signed IDs:                #{correlator.invalid_signed_ids}"
    puts "Suspicious requests (non-GET):     #{correlator.suspicious_rows.size}"
    puts '=' * 80
    puts "\nUnmatched requests (CSV format):"

    correlator.emit_csv($stdout)
  end
end
