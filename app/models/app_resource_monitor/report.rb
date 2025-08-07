###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'csv'
require 'fileutils'

# == AppResourceMonitor::Report
#
# Collect and report resource information
#
class AppResourceMonitor::Report
  def export_to_csv(include_structure_files: false)
    results = collect_results
    timestamp = now.to_fs(:number)
    Dir.mktmpdir do |dir|
      results.each do |name, records|
        write_csv(
          filename: Pathname.new(dir).join("#{name}-#{timestamp}.csv"),
          records: records,
        )
      end
      if include_structure_files
        structure_files.each do |name, content|
          FileUtils.cp(content, Pathname.new(dir).join("#{name}-#{timestamp}.sql"))
        end
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
      'hud_client_references' => AppResourceMonitor::HudReferencesInspector.client_references,
      'hud_enrollment_references' => AppResourceMonitor::HudReferencesInspector.enrollment_references,
      'hud_project_references' => AppResourceMonitor::HudReferencesInspector.project_references,
      'duplicate_hud_ids' => AppResourceMonitor::HudReferencesInspector.duplicate_ids,
    }
  end

  def structure_files
    {
      'app_structure' => Rails.root.join('db/structure.sql').to_s,
      'warehouse_structure' => Rails.root.join('db/warehouse_structure.sql').to_s,
      'reporting_structure' => Rails.root.join('db/reporting_structure.sql').to_s,
      'health_structure' => Rails.root.join('db/health_structure.sql').to_s,
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
        csv << record.values_at(*headers) + [now.to_fs(:db)]
      end
    end
  end
end
