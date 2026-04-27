# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

namespace :app_resource_monitor do
  desc <<~DESC
    Report database and table size growth between two S3 snapshots.

    Arguments (all optional, positional):
      days_back  - how many days to look back          (default: 7)
      database   - substring of the database name      (default: warehouse)
      limit      - number of top tables to display     (default: 10)

    Examples:
      rails app_resource_monitor:growth_report
      rails "app_resource_monitor:growth_report[14]"
      rails "app_resource_monitor:growth_report[7,warehouse,20]"

    Requires an active GrdaWarehouse::RemoteCredentials::S3 row with slug 'app_stats'.
  DESC
  task :growth_report, [:days_back, :database, :limit] => [:environment] do |_task, args|
    days_back = (args[:days_back] || 7).to_i
    database  = args[:database].presence || 'warehouse'
    limit     = (args[:limit] || 10).to_i

    AppResourceMonitor::GrowthReport.new(days_back: days_back, database: database, limit: limit).run
  rescue AppResourceMonitor::GrowthReport::ConfigurationError => e
    abort e.message
  end
end
