# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# == AppResourceMonitor::TableHistory
#
# Downloads every daily postgres_table_stats snapshot in a date range from S3
# and writes a CSV with one row per day for a single table. Useful for charting
# whether a table grew suddenly or gradually over time.
#
# Usage (from rake task):
#   AppResourceMonitor::TableHistory.new(
#     prefix: 'clientname-production',
#     database: 'warehouse_production',
#     table: 'versions',
#     days_back: 30,
#     output_path: '/tmp/versions_history.csv',
#   ).run
#
class AppResourceMonitor::TableHistory < AppResourceMonitor::S3Analysis
  CSV_COLUMNS = ['date', 'table_size', 'index_size', 'total_size', 'num_rows', 'live_tuples', 'dead_tuples', 'dead_tuple_ratio', 'last_vacuum', 'last_analyze'].freeze

  attr_reader :table, :days_back, :output_path

  def initialize(prefix:, database:, table:, days_back: 30, output_path: './table_history.csv')
    super(prefix: prefix, database: database)
    @table       = table.to_s
    @days_back   = days_back.to_i
    @output_path = output_path.to_s
    raise ArgumentError, 'days_back must be a positive integer' unless @days_back.positive?
  end

  def run
    validate_config!

    to_time   = as_of
    from_time = to_time - days_back.days

    keys_in_range = keys_for('postgres_table_stats').select do |key|
      t = snapshot_time(key)
      t >= from_time && t <= to_time
    end

    raise ConfigurationError, "No postgres_table_stats snapshots found under '#{s3_prefix}' in the last #{days_back} days." if keys_in_range.empty?

    db_key = nearest_key('postgres_database_stats', to_time)
    raise ConfigurationError, "No postgres_database_stats snapshots found under '#{s3_prefix}'." if db_key.nil?

    resolved_db = validate_database_name!(db_key)

    csv_rows = keys_in_range.sort_by { |key| snapshot_time(key) }.filter_map do |key|
      row = rows_for(key, resolved_db).find { |r| r['tablename'] == table }
      next unless row

      table_size = row['table_size'].to_i
      index_size = row['index_size'].to_i

      [
        snapshot_time(key).strftime('%Y-%m-%d'),
        table_size,
        index_size,
        table_size + index_size,
        row['num_rows'],
        row['live_tuples'],
        row['dead_tuples'],
        row['dead_tuple_ratio'],
        row['last_vacuum'],
        row['last_analyze'],
      ]
    end

    if csv_rows.empty?
      puts "No data found for table '#{table}' in database '#{resolved_db}'. Check the table name."
    else
      CSV.open(output_path, 'w', headers: CSV_COLUMNS, write_headers: true) do |csv|
        csv_rows.each { |r| csv << r }
      end
      puts "Wrote #{csv_rows.size} data point#{'s' if csv_rows.size != 1} to #{output_path}"
    end
  end
end
