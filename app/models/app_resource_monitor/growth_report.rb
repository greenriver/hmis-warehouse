# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'csv'

# == AppResourceMonitor::GrowthReport
#
# Fetches historical postgres stats from S3 and reports database and table
# size growth between two snapshots. Requires an active RemoteCredentials::S3
# row with slug 'app_stats'.
#
# Usage (from rake task):
#   AppResourceMonitor::GrowthReport.new(days_back: 7, database: 'warehouse', limit: 10).run
#
class AppResourceMonitor::GrowthReport
  class ConfigurationError < StandardError; end

  TIMESTAMP_FORMAT = '%Y%m%d%H%M%S'
  SNAPSHOT_FILENAME_RE = /(\d{14})\.csv\z/

  attr_reader :days_back, :database, :limit

  def initialize(days_back: 7, database: 'warehouse', limit: 10)
    @days_back = days_back.to_i
    @database  = database.to_s
    @limit     = limit.to_i
  end

  def run
    raise ConfigurationError, 'No active app_stats S3 configuration found. Create a GrdaWarehouse::RemoteCredentials::S3 row with slug: "app_stats".' unless s3_config.present?

    to_time   = Time.current
    from_time = to_time - days_back.days

    db_from_key  = nearest_key('postgres_database_stats', from_time)
    db_to_key    = nearest_key('postgres_database_stats', to_time)
    tbl_from_key = nearest_key('postgres_table_stats', from_time)
    tbl_to_key   = nearest_key('postgres_table_stats', to_time)

    missing = [db_from_key, db_to_key, tbl_from_key, tbl_to_key].count(&:nil?)
    raise ConfigurationError, "Could not locate snapshot files under S3 prefix '#{s3_prefix}'. Has the collector run at least once?" if missing.positive?

    db_from  = rows_for_database(db_from_key)
    db_to    = rows_for_database(db_to_key)
    warn_on_ambiguous_database(db_to)
    tbl_from = rows_for_database(tbl_from_key)
    tbl_to   = rows_for_database(tbl_to_key)

    print_report(
      db_from: db_from.first,
      db_to: db_to.first,
      tbl_from: tbl_from,
      tbl_to: tbl_to,
      from_time: snapshot_time(db_from_key),
      to_time: snapshot_time(db_to_key),
    )
  end

  private

  def s3_config
    @s3_config ||= GrdaWarehouse::RemoteCredentials::S3.active.where(slug: 'app_stats').sole
  end

  def s3
    @s3 ||= s3_config.s3
  end

  # Mirrors the prefix construction in CollectStatsJob#perform.
  def s3_prefix
    @s3_prefix ||= [
      s3_config.path,
      [client_name, Rails.env].map(&:strip).join('-'),
    ].join('/')
  end

  def client_name
    ENV.fetch('CLIENT') do
      raise ConfigurationError, 'ENV["CLIENT"] must be set to match the S3 prefix used by the stats collector.'
    end
  end

  def keys_for(file_prefix)
    @keys_cache ||= {}
    @keys_cache[file_prefix] ||= s3.fetch_key_list(prefix: "#{s3_prefix}/#{file_prefix}-")
  end

  def nearest_key(file_prefix, target_time)
    keys_for(file_prefix).min_by { |key| (snapshot_time(key) - target_time).abs }
  end

  def snapshot_time(key)
    match = File.basename(key).match(SNAPSHOT_FILENAME_RE)
    return Time.at(0) unless match

    Time.strptime(match[1], TIMESTAMP_FORMAT)
  end

  def warn_on_ambiguous_database(rows)
    names = rows.map { |r| r['database'] }.uniq
    return if names.size <= 1

    puts "WARNING: '#{database}' matched #{names.size} databases: #{names.join(', ')}"
    puts "  Using '#{names.first}'. Pass a more specific name to disambiguate."
    puts ''
    rows.select! { |r| r['database'] == names.first }
  end

  def rows_for_database(key)
    io = s3.get_as_io(key: key)
    io.rewind
    CSV.parse(io.read, headers: true).map(&:to_h).select { |r| r['database']&.include?(database) }
  end

  def print_report(db_from:, db_to:, tbl_from:, tbl_to:, from_time:, to_time:)
    puts ''
    puts "Database Growth Report: #{database}"
    puts "Period: #{from_time.strftime('%Y-%m-%d %H:%M')} → #{to_time.strftime('%Y-%m-%d %H:%M')} (#{days_back} days)"
    puts ''

    if db_from.nil? || db_to.nil?
      puts "No rows found for database matching '#{database}'. Check that the database argument is a substring of the actual database name in the CSV."
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

  def format_bytes(bytes)
    n = bytes.to_i.abs
    if n >= 1_073_741_824
      format('%.1f GB', n.to_f / 1_073_741_824)
    elsif n >= 1_048_576
      format('%.1f MB', n.to_f / 1_048_576)
    elsif n >= 1_024
      format('%.1f KB', n.to_f / 1_024)
    else
      "#{n} B"
    end
  end

  def format_delta_bytes(num)
    "#{n >= 0 ? '+' : '-'}#{format_bytes(num)}"
  end

  def format_pct(pct)
    "#{pct >= 0 ? '+' : ''}#{pct}%"
  end
end
