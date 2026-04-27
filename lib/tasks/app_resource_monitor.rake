# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

namespace :app_resource_monitor do
  desc <<~DESC
    Report database and table size growth between two S3 snapshots.

    Arguments (positional):
      prefix     - S3 sub-prefix identifying the target environment (e.g. "clientname-production")
      days_back  - how many days to look back          (default: 7)
      database   - substring of the database name      (default: warehouse)
      limit      - number of top tables to display     (default: 10)

    Examples:
      rails "app_resource_monitor:growth_report[clientname-production]"
      rails "app_resource_monitor:growth_report[clientname-production,14]"
      rails "app_resource_monitor:growth_report[clientname-production,7,warehouse,20]"

    Requires an active GrdaWarehouse::RemoteCredentials::S3 row with slug 'app_stats'.
  DESC
  task :growth_report, [:prefix, :days_back, :database, :limit] => [:environment] do |_task, args|
    prefix    = args.fetch(:prefix) { abort 'prefix argument is required (e.g. "clientname-production")' }
    days_back = (args[:days_back] || 7).to_i
    database  = args[:database].presence || 'warehouse'
    limit     = (args[:limit] || 10).to_i

    AppResourceMonitor::GrowthReport.new(prefix: prefix, days_back: days_back, database: database, limit: limit).run
  rescue AppResourceMonitor::S3Report::ConfigurationError => e
    abort e.message
  end

  desc <<~DESC
    Export a daily time-series CSV for a single table's size metrics.

    Arguments (positional):
      prefix      - S3 sub-prefix identifying the target environment (e.g. "clientname-production")
      table       - exact table name to inspect (e.g. "versions")
      database    - exact database name (e.g. "warehouse_production")
      days_back   - how many days to look back                        (default: 30)
      output_path - path for the output CSV file                      (default: ./table_history.csv)

    Examples:
      rails "app_resource_monitor:table_history[clientname-production,versions,warehouse_production]"
      rails "app_resource_monitor:table_history[clientname-production,versions,warehouse_production,90,/tmp/versions.csv]"

    Requires an active GrdaWarehouse::RemoteCredentials::S3 row with slug 'app_stats'.
  DESC
  task :table_history, [:prefix, :table, :database, :days_back, :output_path] => [:environment] do |_task, args|
    prefix      = args.fetch(:prefix)   { abort 'prefix argument is required (e.g. "clientname-production")' }
    table       = args.fetch(:table)    { abort 'table argument is required (e.g. "versions")' }
    database    = args.fetch(:database) { abort 'database argument is required (e.g. "warehouse_production")' }
    days_back   = (args[:days_back] || 30).to_i
    output_path = args[:output_path].presence || './table_history.csv'

    AppResourceMonitor::TableHistory.new(prefix: prefix, table: table, database: database, days_back: days_back, output_path: output_path).run
  rescue AppResourceMonitor::S3Report::ConfigurationError => e
    abort e.message
  end
end
