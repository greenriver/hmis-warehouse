# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'csv'

# == AppResourceMonitor::S3Report
#
# Base class for reports that read historical postgres stats CSVs from S3.
# Provides shared S3 connection, key listing, snapshot parsing, and
# database name resolution. Subclasses implement `run`.
#
class AppResourceMonitor::S3Report
  class ConfigurationError < StandardError; end

  TIMESTAMP_FORMAT = '%Y%m%d%H%M%S'
  SNAPSHOT_FILENAME_RE = /(\d{14})\.csv\z/

  attr_reader :prefix, :database

  def initialize(prefix:, database:)
    @prefix   = prefix.to_s
    @database = database.to_s
  end

  private

  def validate_config!
    raise ConfigurationError, 'No active app_stats S3 configuration found. Create a GrdaWarehouse::RemoteCredentials::S3 row with slug: "app_stats".' unless s3_config.present?
  end

  def s3_config
    @s3_config ||= GrdaWarehouse::RemoteCredentials::S3.active.where(slug: 'app_stats').sole
  end

  def s3
    @s3 ||= s3_config.s3
  end

  def s3_prefix
    @s3_prefix ||= [s3_config.path, prefix].join('/')
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

  def resolve_database_name(db_key)
    all_rows = parse_csv(db_key)
    available = all_rows.map { |r| r['database'] }.uniq.compact

    raise ConfigurationError, "No database named '#{database}' found in snapshot. Available: #{available.join(', ')}" unless available.include?(database)

    database
  end

  def rows_for(key, exact_db_name)
    parse_csv(key).select { |r| r['database'] == exact_db_name }
  end

  def parse_csv(key)
    io = s3.get_as_io(key: key)
    io.rewind
    CSV.parse(io.read, headers: true).map(&:to_h)
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
    "#{num >= 0 ? '+' : '-'}#{format_bytes(num)}"
  end

  def format_pct(pct)
    "#{pct >= 0 ? '+' : ''}#{pct}%"
  end
end
