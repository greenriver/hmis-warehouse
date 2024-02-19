###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'csv'

# == AppResourceMonitor::Report
#
# Collect and report resource information
#
class AppResourceMonitor::Report
  def export_to_csv
    results = collect_results
    timestamp = now.to_s(:number)
    Dir.mktmpdir do |dir|
      results.each do |name, records|
        write_csv(
          filename: Pathname.new(dir).join("#{name}-#{timestamp}.csv"),
          records: records,
        )
      end
      yield dir
    end
  end

  protected

  def collect_results
    {
      'postgres_database_stats' => AppResourceMonitor::PostgresInspector.flat_map(&:database_stats),
      'postgres_table_stats' => AppResourceMonitor::PostgresInspector.flat_map(&:table_stats),
      'postgres_toast_stats' => AppResourceMonitor::PostgresInspector.flat_map(&:toast_stats),
      'postgres_index_stats' => AppResourceMonitor::PostgresInspector.flat_map(&:index_stats),
      'app_record_stats' => AppResourceMonitor::AppInspector.utilization_stats,
      'app_activity' => AppResourceMonitor::AppInspector.activity_stats(range: ((now - 1.day)...now)),
    }
  end

  def now
    @now ||= Time.current
  end

  def write_csv(filename:, records:)
    return if records.empty?

    ::CSV.open(filename.to_s, 'w') do |csv|
      headers = records.first.keys
      csv << headers + ['timestamp']
      records.each do |record|
        csv << record.values_at(*headers) + [now.to_s(:db)]
      end
    end
  end
end
