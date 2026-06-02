# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Detects and optionally removes duplicate/redundant db indexes Works
# by inspecting what actually exists in the current database
class Dba::StagingIndexDeduplicator
  attr_reader :conn, :dry_run, :table_pattern

  def initialize(table_pattern:, dry_run: true)
    @conn = GrdaWarehouseBase.connection
    @table_pattern = table_pattern
    @dry_run = dry_run
  end

  def run!
    tables = staging_tables
    puts header(tables.count)

    drops = []

    tables.each do |table|
      indexes = indexes_for(table)
      next if indexes.size < 2

      table_drops, keepers = find_droppable(indexes)
      next if table_drops.empty?

      report_table(table, table_drops, keepers)
      drops.concat(table_drops)
    end

    execute_drops(drops)
    print_summary(drops)
  end

  private

  def staging_tables
    conn.select_values(<<~SQL)
      SELECT tablename FROM pg_tables
      WHERE schemaname = 'public'
        AND tablename LIKE #{conn.quote(table_pattern)}
      ORDER BY tablename
    SQL
  end

  def indexes_for(table)
    indexes = conn.select_all(<<~SQL).to_a
      SELECT
        i.relname AS index_name,
        am.amname AS access_method,
        pg_get_indexdef(i.oid) AS index_def,
        array_to_json(ARRAY(
          SELECT pg_get_indexdef(i.oid, k + 1, true)
          FROM generate_subscripts(ix.indkey, 1) AS k
          WHERE k < ix.indnkeyatts
          ORDER BY k
        )) AS column_names_json,
        array_to_json(ARRAY(
          SELECT pg_get_indexdef(i.oid, k + 1, true)
          FROM generate_subscripts(ix.indkey, 1) AS k
          WHERE k >= ix.indnkeyatts
          ORDER BY k
        )) AS include_columns_json,
        ix.indisunique AS is_unique,
        ix.indisprimary AS is_primary,
        ix.indpred IS NOT NULL AS is_partial,
        pg_get_expr(ix.indpred, ix.indrelid) AS predicate,
        pg_relation_size(i.oid) AS index_size_bytes
      FROM pg_index ix
      JOIN pg_class t ON t.oid = ix.indrelid
      JOIN pg_class i ON i.oid = ix.indexrelid
      JOIN pg_namespace n ON n.oid = t.relnamespace
      JOIN pg_am am ON i.relam = am.oid
      WHERE t.relname = #{conn.quote(table)}
        AND n.nspname = 'public'
      ORDER BY index_name
    SQL

    indexes.each do |idx|
      idx['column_names'] = JSON.parse(idx['column_names_json'])
      idx['include_columns'] = JSON.parse(idx['include_columns_json'])
    end

    indexes
  end

  def find_droppable(indexes)
    drops = []
    exact_drops, keepers = find_exact_duplicates(indexes)
    drops.concat(exact_drops)

    remaining_indexes = indexes.reject { |idx| drops.any? { |d| d[:index_name] == idx['index_name'] } }
    drops.concat(find_prefix_redundancies(remaining_indexes))

    drops.uniq! { |d| d[:index_name] }
    [drops, keepers]
  end

  # When multiple indexes cover identical columns, keep the "best" one:
  # primary > unique > oldest (alphabetically first name as proxy)
  def find_exact_duplicates(indexes)
    drops = []
    keepers = []

    # Group by access method, columns, and partial predicate to ensure we only
    # deduplicate truly identical index definitions.
    indexes.group_by { |idx| [idx['access_method'], idx['column_names'], idx['predicate']] }.each_value do |group|
      next if group.size < 2

      sorted = group.sort_by do |idx|
        [
          idx['is_primary'] ? 0 : 1,
          idx['is_unique'] ? 0 : 1,
          idx['index_name'],
        ]
      end

      keeper = sorted.first
      keepers << keeper['index_name']
      sorted[1..].each do |idx|
        label = idx['is_unique'] == keeper['is_unique'] ? 'exact duplicate of' : 'subsumed by'
        drops << {
          index_name: idx['index_name'],
          index_def: idx['index_def'],
          size_bytes: idx['index_size_bytes'].to_i,
          reason: "#{label} #{keeper['index_name']} on (#{idx['column_names'].join(', ')})",
        }
      end
    end

    [drops, keepers]
  end

  # A non-unique, non-partial single-column index is redundant if a composite
  # index starts with the same column. We're conservative: only flag if the
  # shorter index has no properties the longer one lacks.
  def find_prefix_redundancies(indexes)
    drops = []
    non_partial = indexes.reject { |idx| idx['is_partial'] }

    non_partial.each do |shorter|
      next if shorter['is_primary']

      # A unique index enforces a constraint that a longer index cannot enforce.
      # (e.g. unique on (a) is stronger than unique on (a, b)).
      # Therefore, a unique index is never redundant as a prefix.
      next if shorter['is_unique']

      cols_short = shorter['column_names']

      include_short = shorter['include_columns']

      non_partial.each do |longer|
        next if longer == shorter
        next if longer['access_method'] != shorter['access_method']

        cols_long = longer['column_names']

        is_prefix = cols_long.size > cols_short.size && cols_long[0...cols_short.size] == cols_short
        next unless is_prefix

        # The shorter index's INCLUDE columns enable index-only scans that the
        # longer index can only replicate if it carries them as key or INCLUDE
        # columns itself.
        if include_short.any?
          covered = cols_long + longer['include_columns']
          next unless include_short.all? { |col| covered.include?(col) }
        end

        drops << {
          index_name: shorter['index_name'],
          index_def: shorter['index_def'],
          size_bytes: shorter['index_size_bytes'].to_i,
          reason: "prefix-redundant — covered by #{longer['index_name']} on (#{cols_long.join(', ')})",
        }
        break # only need one covering index to justify removal
      end
    end

    drops
  end

  def execute_drops(drops)
    return if drops.empty?

    puts
    puts '=' * 80
    if dry_run
      puts 'DRY RUN — the following DROP statements would be executed:'
    else
      puts 'EXECUTING drops...'
    end
    puts '=' * 80

    drops.each do |drop|
      sql = "DROP INDEX IF EXISTS #{conn.quote_column_name(drop[:index_name])};"

      if dry_run
        puts "  #{sql}"
        puts "    -- #{drop[:reason]}"
      else
        puts "  Dropping #{drop[:index_name]} (#{format_size(drop[:size_bytes])})..."
        puts "    -- #{drop[:reason]}"
        conn.execute("SET lock_timeout = '2s'")
        conn.execute(sql)
      end
    end
  end

  def print_summary(drops)
    puts
    puts '=' * 80
    puts 'SUMMARY'
    puts '=' * 80
    puts "Redundant indexes found: #{drops.count}"
    total_bytes = drops.sum { |d| d[:size_bytes] }
    puts "Storage reclaimable: #{format_size(total_bytes)}"
    puts
    if dry_run && drops.any?
      puts 'Re-run with dry_run: false to execute.'
    elsif drops.empty?
      puts 'No redundant indexes found. Nothing to do.'
    else
      puts 'Done. Indexes have been dropped.'
    end
  end

  def report_table(table, drops, keepers)
    puts
    puts '-' * 80
    puts "Table: #{table} (#{drops.count} redundant)"
    puts '-' * 80
    keepers.each { |name| puts "  Keeping: #{name}" }
    drops.each do |drop|
      puts "  Drop: #{drop[:index_name]} (#{format_size(drop[:size_bytes])})"
      puts "    #{drop[:reason]}"
    end
  end

  def header(count)
    lines = []
    lines << '=' * 80
    lines << 'HMIS CSV Importer Staging Tables — Redundant Index Detection'
    lines << '=' * 80
    lines << ''
    lines << "Mode: #{dry_run ? 'DRY RUN (no changes)' : 'EXECUTE (will drop indexes)'}"
    lines << "Staging tables found: #{count}"
    lines << ''
    lines.join("\n")
  end

  def format_size(bytes)
    ActiveSupport::NumberHelper.number_to_human_size(bytes)
  end
end
