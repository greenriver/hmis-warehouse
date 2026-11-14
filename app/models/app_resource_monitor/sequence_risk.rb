###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# == AppResourceMonitor::SequenceRisk
#
# Downloads the nearest postgres_sequence_stats snapshot from S3 and prints
# the top N sequences by percentage of their max value consumed. Useful for
# spotting tables whose primary key sequence is approaching exhaustion.
#
# Usage:
#   AppResourceMonitor::SequenceRisk.new(
#     prefix: 'clientname-production',
#     limit:  20,
#   ).run
#
class AppResourceMonitor::SequenceRisk < AppResourceMonitor::S3Analysis
  attr_reader :limit

  def initialize(prefix:, database: nil, limit: 20, as_of: nil)
    super(prefix: prefix, database: database, as_of: as_of)
    @limit = limit.to_i
  end

  def run
    validate_config!

    key = nearest_key('postgres_sequence_stats', as_of)
    raise ConfigurationError, "No postgres_sequence_stats snapshots found under '#{s3_prefix}'. Has the collector run since the sequence_stats metric was added?" if key.nil?

    rows = parse_csv(key)
    rows = rows_for_database(rows) if database.present?

    print_report(rows: rows, snapshot_at: snapshot_time(key))
  end

  private

  # Raise on an unknown database name rather than printing an empty report,
  # which would read as "nothing at risk".
  def rows_for_database(rows)
    available = rows.map { |r| r['database'] }.uniq.compact
    raise ConfigurationError, "No database named '#{database}' found in snapshot. Available: #{available.join(', ')}" unless available.include?(database)

    rows.select { |r| r['database'] == database }
  end

  def print_report(rows:, snapshot_at:)
    puts ''
    puts "Sequence Exhaustion Risk: #{prefix}"
    puts "Snapshot: #{snapshot_at.strftime('%Y-%m-%d %H:%M')}"
    puts ''

    if rows.empty?
      puts 'No sequence data found in snapshot.'
      return
    end

    sorted = rows.sort_by { |r| -r['pct_used'].to_f }.first(limit)

    puts format('  %-4s %-30s %-40s %-14s %s', '#', 'Database', 'Table.Column', 'Used %', 'Current / Max')
    puts "  #{'-' * 108}"

    sorted.each_with_index do |row, i|
      table_col = "#{row['tablename']}.#{row['column_name']}"
      current = format_number(row['last_value'].to_i)
      max     = format_number(row['max_value'].to_i)

      puts format('  %-4d %-30s %-40s %-14s %s', i + 1, row['database'], table_col, "#{format('%.4f', row['pct_used'].to_f)}%", "#{current} / #{max}")
    end
    puts ''
  end

  def format_number(val)
    val.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
