###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::Benchmarking
  # Snapshots PostgreSQL's cumulative per-table statistics so a benchmark run
  # can report what the import actually did to each table: rows written
  # (n_tup_ins/upd/del), HOT-update eligibility (n_tup_hot_upd), dead-tuple
  # accumulation, vacuum activity, and access patterns (seq_scan vs idx_scan).
  # These counters are scale-invariant evidence for write-amplification and
  # query-plan changes, independent of wall-clock noise.
  #
  # Counters are table-wide, not per data source; runs are only attributable
  # when the database is otherwise idle (see #other_active_connections).
  class PgStats
    COUNTERS = [
      'seq_scan',
      'seq_tup_read',
      'idx_scan',
      'idx_tup_fetch',
      'n_tup_ins',
      'n_tup_upd',
      'n_tup_del',
      'n_tup_hot_upd',
      'n_live_tup',
      'n_dead_tup',
      'vacuum_count',
      'autovacuum_count',
      'analyze_count',
      'autoanalyze_count',
    ].freeze

    def initialize(connection: GrdaWarehouseBase.connection)
      @connection = connection
    end

    def snapshot
      sql = "SELECT relname, #{COUNTERS.join(', ')} FROM pg_stat_user_tables WHERE schemaname = 'public'"
      @connection.select_all(sql).rows.each_with_object({}) do |row, snapshot|
        relname, *values = row
        snapshot[relname] = COUNTERS.zip(values.map(&:to_i)).to_h
      end
    end

    def other_active_connections
      @connection.select_value(<<~SQL).to_i
        SELECT count(*) FROM pg_stat_activity
        WHERE datname = current_database()
          AND pid <> pg_backend_pid()
          AND state <> 'idle'
      SQL
    end

    # Per-table counter changes between two snapshots; tables with no changes
    # are dropped so results stay small. Negative deltas are preserved (e.g.,
    # n_dead_tup shrinking when vacuum runs mid-import).
    def self.delta(before, after)
      after.each_with_object({}) do |(table, counters), result|
        base = before.fetch(table, {})
        changes = counters.each_with_object({}) do |(counter, value), accumulator|
          diff = value - base.fetch(counter, 0)
          accumulator[counter] = diff unless diff.zero?
        end
        result[table] = changes if changes.any?
      end
    end
  end
end
