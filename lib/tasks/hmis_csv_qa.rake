###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

namespace :hmis_csv do
  namespace :qa do
    desc <<~DESC
      Compare two already-imported data sources table-by-table for QA.

      Useful for validating that a refactored importer produces identical warehouse
      output to the original: import the same HUD CSVs into two separate data
      sources, then run this task to diff the results.

      Expected drift (surrogate PKs, data_source_id, import timestamps) is
      automatically excluded from comparison.

      Usage:
        rails "hmis_csv:qa:compare[DS_A_ID,DS_B_ID]"

      Re-import one data source, then re-run to test idempotency:
        rails "hmis_csv:qa:compare[DS_A_ID,DS_B_ID]"
    DESC
    task :compare, [:ds_a_id, :ds_b_id] => :environment do |_, args|
      ds_a_id = Integer(args.fetch(:ds_a_id) { abort 'DS_A_ID required' })
      ds_b_id = Integer(args.fetch(:ds_b_id) { abort 'DS_B_ID required' })

      HmisCsvQaComparison.new(ds_a_id: ds_a_id, ds_b_id: ds_b_id).run
    end
  end
end

# Compares two already-imported data sources row-by-row across every importable
# warehouse table. Intended for manual QA — run after importing the same HUD CSV
# export into two independent data sources, then re-run after a second import to
# verify idempotency.
#
# Columns excluded from comparison (expected to differ between any two imports):
#   - id                  — surrogate PK, auto-assigned
#   - data_source_id      — differs by design
#   - ExportID            — references each source's own Export record
#   - pending_date_deleted — transient import state, always NULL after import
#   - DateDeleted         — timestamp checked as NULL vs non-NULL, not exact value
#
# source_hash IS included: it is a content fingerprint derived from HUD CSV
# fields; identical inputs must produce identical hashes.
class HmisCsvQaComparison
  MAX_DIFFS_PER_TABLE = 20
  CONTENT_BATCH = 5_000

  def initialize(ds_a_id:, ds_b_id:)
    @ds_a_id = ds_a_id
    @ds_b_id = ds_b_id
  end

  def run
    puts header

    pass_count = 0
    fail_count = 0

    importable_files.each do |file_name, importer_klass|
      result = compare_table(file_name, importer_klass)
      result[:pass] ? pass_count += 1 : fail_count += 1
      puts format_result(file_name, importer_klass.warehouse_class, result)
    end

    puts "\n#{'=' * 50}"
    puts "#{pass_count + fail_count} tables compared — #{pass_count} PASS, #{fail_count} FAIL"

    exit(fail_count.positive? ? 1 : 0)
  end

  private

  def header
    ds_a = GrdaWarehouse::DataSource.find_by(id: @ds_a_id) || abort("Data source #{@ds_a_id} not found")
    ds_b = GrdaWarehouse::DataSource.find_by(id: @ds_b_id) || abort("Data source #{@ds_b_id} not found")

    <<~TEXT
      #{'=' * 50}
      HMIS CSV QA — Cross-Source Comparison
      #{'=' * 50}
      A: DS #{@ds_a_id} — #{ds_a.name}
      B: DS #{@ds_b_id} — #{ds_b.name}
      Version: #{version}
      #{'=' * 50}
    TEXT
  end

  def version
    @version ||= begin
      v_a = HmisCsvImporter::Importer::ImporterLog.
        where(data_source_id: @ds_a_id).
        order(completed_at: :desc).
        pick(:version)
      v_b = HmisCsvImporter::Importer::ImporterLog.
        where(data_source_id: @ds_b_id).
        order(completed_at: :desc).
        pick(:version)

      warn "WARNING: Data sources were imported with different versions (A=#{v_a}, B=#{v_b}). Using A (#{v_a})." if v_a && v_b && v_a != v_b

      v_a || v_b || abort('No completed import logs found for either data source. Import the data first.')
    end
  end

  def importable_files
    @importable_files ||= begin
      data_lake = Rails.application.config.hmis_data_lakes[version]&.constantize
      abort("No data lake module registered for version #{version}") unless data_lake

      data_lake.importable_files
    end
  end

  # Returns a result hash describing the comparison for one warehouse table.
  def compare_table(_file_name, importer_klass)
    wh_class = importer_klass.warehouse_class
    conn     = wh_class.connection
    table    = wh_class.quoted_table_name
    key      = wh_class.hud_key
    key_col  = conn.quote_column_name(key)

    scope_a = full_scope(wh_class, @ds_a_id)
    scope_b = full_scope(wh_class, @ds_b_id)

    count_a = scope_a.count
    count_b = scope_b.count

    # Keys present in one source but absent in the other — use NOT EXISTS to
    # avoid false negatives from NULL hud_keys (NOT IN + NULL = no rows).
    only_in_a = scope_a.where(<<~SQL).limit(MAX_DIFFS_PER_TABLE + 1).pluck(key)
      NOT EXISTS (
        SELECT 1 FROM #{table} b
        WHERE b.data_source_id = #{conn.quote(@ds_b_id)}
          AND b.#{key_col} = #{table}.#{key_col}
      )
    SQL

    only_in_b = scope_b.where(<<~SQL).limit(MAX_DIFFS_PER_TABLE + 1).pluck(key)
      NOT EXISTS (
        SELECT 1 FROM #{table} a
        WHERE a.data_source_id = #{conn.quote(@ds_a_id)}
          AND a.#{key_col} = #{table}.#{key_col}
      )
    SQL

    # Keys present in both but with different content (source_hash mismatch)
    # or differing deleted status.
    content_mismatch_keys = conn.execute(<<~SQL).map { |r| r[key.to_s] }
      SELECT a.#{key_col}
      FROM #{table} a
      JOIN #{table} b ON b.#{key_col} = a.#{key_col}
        AND b.data_source_id = #{conn.quote(@ds_b_id)}
      WHERE a.data_source_id = #{conn.quote(@ds_a_id)}
        AND (
          a.source_hash IS DISTINCT FROM b.source_hash
          OR (a."DateDeleted" IS NULL) != (b."DateDeleted" IS NULL)
        )
      LIMIT #{MAX_DIFFS_PER_TABLE + 1}
    SQL

    diffs = build_diffs(wh_class, scope_a, scope_b, key, only_in_a, only_in_b, content_mismatch_keys)

    {
      pass: only_in_a.empty? && only_in_b.empty? && content_mismatch_keys.empty?,
      count_a: count_a,
      count_b: count_b,
      only_in_a: only_in_a,
      only_in_b: only_in_b,
      content_mismatch_keys: content_mismatch_keys,
      diffs: diffs,
    }
  end

  def build_diffs(wh_class, scope_a, scope_b, key, only_in_a, only_in_b, content_mismatch_keys)
    diffs = []

    only_in_a.first(MAX_DIFFS_PER_TABLE).each { |k| diffs << { type: :only_in_a, key: k } }
    only_in_b.first(MAX_DIFFS_PER_TABLE).each { |k| diffs << { type: :only_in_b, key: k } }

    content_mismatch_keys.first(MAX_DIFFS_PER_TABLE).each do |k|
      row_a = scope_a.find_by(key => k)
      row_b = scope_b.find_by(key => k)
      next unless row_a && row_b

      col_diffs = comparable_columns(wh_class).filter_map do |col|
        val_a = row_a[col]
        val_b = row_b[col]
        { column: col, a: val_a, b: val_b } if val_a != val_b
      end

      diffs << { type: :content, key: k, col_diffs: col_diffs } if col_diffs.any?
    end

    diffs
  end

  # Scope that includes soft-deleted rows for paranoid models.
  # Uses unscoped so acts_as_paranoid's default DateDeleted IS NULL filter
  # is removed, giving us all rows for that data source.
  def full_scope(wh_class, ds_id)
    wh_class.unscoped.where(data_source_id: ds_id)
  end

  # HUD CSV fields that should be identical between two imports of the same data.
  # Excludes ExportID (references each source's own Export record) and the hud_key
  # itself (used for matching, not comparison). source_hash is appended as a
  # single-value content fingerprint.
  def comparable_columns(wh_class)
    (wh_class.hud_csv_headers(version: version) - [wh_class.hud_key, :ExportID]).
      map(&:to_s).
      then { |cols| cols + ['source_hash'] }.
      uniq
  end

  def format_result(file_name, wh_class, result)
    status     = result[:pass] ? 'PASS' : 'FAIL'
    count_info = if result[:count_a] == result[:count_b]
      "(#{result[:count_a]} rows)"
    else
      "(A: #{result[:count_a]} rows, B: #{result[:count_b]} rows)"
    end

    lines = ["#{file_name.ljust(38)} #{status}  #{count_info}"]
    return lines.first if result[:pass]

    result[:diffs].each do |diff|
      case diff[:type]
      when :only_in_a
        lines << "  [only in A] #{wh_class.hud_key}=#{diff[:key]}"
      when :only_in_b
        lines << "  [only in B] #{wh_class.hud_key}=#{diff[:key]}"
      when :content
        lines << "  [mismatch]  #{wh_class.hud_key}=#{diff[:key]}"
        diff[:col_diffs].each do |cd|
          lines << "              #{cd[:column].ljust(20)} A=#{cd[:a].inspect}  B=#{cd[:b].inspect}"
        end
      end
    end

    truncated = [result[:only_in_a], result[:only_in_b], result[:content_mismatch_keys]].any? do |list|
      list.size > MAX_DIFFS_PER_TABLE
    end
    lines << "  (showing first #{MAX_DIFFS_PER_TABLE} of each mismatch type — re-run after fixing to see remaining)" if truncated

    lines.join("\n")
  end
end
