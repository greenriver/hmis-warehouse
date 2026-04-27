# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# == AppResourceMonitor::GrowthReport
#
# Fetches historical postgres stats from S3 and reports database and table
# size growth between two snapshots. Requires an active RemoteCredentials::S3
# row with slug 'app_stats'.
#
# Usage (from rake task):
#   AppResourceMonitor::GrowthReport.new(prefix: 'clientname-production', database: 'warehouse_production', days_back: 7, limit: 10).run
#
class AppResourceMonitor::GrowthReport < AppResourceMonitor::S3Report
  attr_reader :days_back, :limit

  def initialize(prefix:, database:, days_back: 7, limit: 10)
    super(prefix: prefix, database: database)
    @days_back = days_back.to_i
    @limit     = limit.to_i
  end

  def run
    validate_config!

    to_time   = Time.current
    from_time = to_time - days_back.days

    db_from_key  = nearest_key('postgres_database_stats', from_time)
    db_to_key    = nearest_key('postgres_database_stats', to_time)
    tbl_from_key = nearest_key('postgres_table_stats', from_time)
    tbl_to_key   = nearest_key('postgres_table_stats', to_time)

    missing = [db_from_key, db_to_key, tbl_from_key, tbl_to_key].count(&:nil?)
    raise ConfigurationError, "Could not locate snapshot files under S3 prefix '#{s3_prefix}'. Has the collector run at least once?" if missing.positive?

    resolved_db = resolve_database_name(db_to_key)

    db_from  = rows_for(db_from_key, resolved_db)
    db_to    = rows_for(db_to_key, resolved_db)
    tbl_from = rows_for(tbl_from_key, resolved_db)
    tbl_to   = rows_for(tbl_to_key, resolved_db)

    print_report(
      resolved_db: resolved_db,
      db_from: db_from.first,
      db_to: db_to.first,
      tbl_from: tbl_from,
      tbl_to: tbl_to,
      from_time: snapshot_time(db_from_key),
      to_time: snapshot_time(db_to_key),
    )
  end

  private

  def print_report(resolved_db:, db_from:, db_to:, tbl_from:, tbl_to:, from_time:, to_time:)
    puts ''
    puts "Database Growth Report: #{resolved_db}"
    puts "Period: #{from_time.strftime('%Y-%m-%d %H:%M')} → #{to_time.strftime('%Y-%m-%d %H:%M')} (#{days_back} days)"
    puts ''

    if db_from.nil? || db_to.nil?
      puts "No rows found for database matching '#{database}' in one or both snapshots."
      return
    end

    from_size = db_from['total_size'].to_i
    to_size   = db_to['total_size'].to_i
    db_delta  = to_size - from_size
    db_pct    = from_size > 0 ? (db_delta.to_f / from_size * 100).round(1) : 0.0

    puts "Total DB size:  #{format_bytes(from_size)} → #{format_bytes(to_size)}  (#{format_delta_bytes(db_delta)}, #{format_pct(db_pct)})"
    puts ''

    tbl_from_index = tbl_from.index_by { |r| r['tablename'] }
    tbl_deltas = tbl_to.filter_map do |row|
      name   = row['tablename']
      before = tbl_from_index[name]
      next unless before

      before_total = before['table_size'].to_i + before['index_size'].to_i
      after_total  = row['table_size'].to_i + row['index_size'].to_i
      { name: name, delta: after_total - before_total, before: before_total, after: after_total }
    end.sort_by { |r| -r[:delta] }.first(limit)

    puts "Top #{tbl_deltas.size} tables by total size growth:"
    puts format('  %-4s %-45s %-18s %s', '#', 'Table', 'Size change', '% of DB growth')
    puts "  #{'-' * 78}"
    tbl_deltas.each_with_index do |row, i|
      pct_of_total = db_delta != 0 ? (row[:delta].to_f / db_delta * 100).round(1) : 0.0
      puts format('  %-4d %-45s %-18s %s', i + 1, row[:name], format_delta_bytes(row[:delta]), format_pct(pct_of_total))
    end
    puts ''
  end
end
