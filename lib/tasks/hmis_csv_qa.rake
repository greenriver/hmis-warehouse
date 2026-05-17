###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

namespace :hmis_csv do
  namespace :qa do
    # Columns excluded from comparison (expected to differ between any two imports):
    #   - id                  — surrogate PK, auto-assigned
    #   - data_source_id      — differs by design
    #   - ExportID            — references each source's own Export record
    #   - SourceID            — identifies the originating upload/system; differs
    #                           when imports come from separate HMIS installations
    #   - pending_date_deleted — transient import state, always NULL after import
    #   - DateDeleted         — timestamp checked as NULL vs non-NULL, not exact value
    #   - source_hash         — set asynchronously by post-import jobs; NULL until
    #                           reprocessing completes, so timing affects its value
    hmis_csv_qa_comparison = Class.new do
      def initialize(ds_a_id:, ds_b_id:)
        @ds_a_id = ds_a_id
        @ds_b_id = ds_b_id
      end

      def run
        puts header

        pass_count = 0
        fail_count = 0

        importable_files.each do |file_name, importer_klass|
          result = compare_table(importer_klass)
          result[:pass] ? pass_count += 1 : fail_count += 1
          puts format_result(file_name, importer_klass.warehouse_class, result)
        end

        puts "\n#{'=' * 50}"
        puts "#{pass_count + fail_count} tables compared — #{pass_count} PASS, #{fail_count} FAIL"

        fail_count
      end

      private

      def max_diffs_per_table = 20

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

      def compare_table(importer_klass)
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
        only_in_a = scope_a.where(<<~SQL).limit(max_diffs_per_table + 1).pluck(key)
          NOT EXISTS (
            SELECT 1 FROM #{table} b
            WHERE b.data_source_id = #{conn.quote(@ds_b_id)}
              AND b.#{key_col} = #{table}.#{key_col}
          )
        SQL

        only_in_b = scope_b.where(<<~SQL).limit(max_diffs_per_table + 1).pluck(key)
          NOT EXISTS (
            SELECT 1 FROM #{table} a
            WHERE a.data_source_id = #{conn.quote(@ds_a_id)}
              AND a.#{key_col} = #{table}.#{key_col}
          )
        SQL

        # Keys present in both but with differing field values or deleted status.
        # Collect all comparison conditions, then skip the content-mismatch query
        # entirely when there are no comparable columns (e.g. a table whose only
        # HUD headers are the key, ExportID, and SourceID).
        conditions = comparable_columns(wh_class).map do |col|
          "a.#{conn.quote_column_name(col)} IS DISTINCT FROM b.#{conn.quote_column_name(col)}"
        end
        conditions << %((a."DateDeleted" IS NULL) != (b."DateDeleted" IS NULL)) if wh_class.column_names.include?('DateDeleted')

        content_mismatch_keys = if conditions.any?
          conn.execute(<<~SQL).map { |r| r[key.to_s] }
            SELECT a.#{key_col}
            FROM #{table} a
            JOIN #{table} b ON b.#{key_col} = a.#{key_col}
              AND b.data_source_id = #{conn.quote(@ds_b_id)}
            WHERE a.data_source_id = #{conn.quote(@ds_a_id)}
              AND (
                #{conditions.join("\n                OR ")}
              )
            LIMIT #{max_diffs_per_table + 1}
          SQL
        else
          []
        end

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

        only_in_a.first(max_diffs_per_table).each { |k| diffs << { type: :only_in_a, key: k } }
        only_in_b.first(max_diffs_per_table).each { |k| diffs << { type: :only_in_b, key: k } }

        keys_to_diff = content_mismatch_keys.first(max_diffs_per_table)
        rows_a = scope_a.where(key => keys_to_diff).index_by { |r| r[key.to_s] }
        rows_b = scope_b.where(key => keys_to_diff).index_by { |r| r[key.to_s] }
        cols = comparable_columns(wh_class)

        keys_to_diff.each do |k|
          row_a = rows_a[k]
          row_b = rows_b[k]
          next unless row_a && row_b

          col_diffs = cols.filter_map do |col|
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

      # See excluded-columns list at top of class for rationale.
      # Intersects with column_names so HUD spec names that don't exactly match
      # the DB column (e.g. renamed or corrected typos) won't crash the SQL.
      def comparable_columns(wh_class)
        @comparable_columns_cache ||= {}
        @comparable_columns_cache[wh_class] ||= begin
          hud_headers = (wh_class.hud_csv_headers(version: version) - [wh_class.hud_key, :ExportID, :SourceID]).map(&:to_s)
          hud_headers & wh_class.column_names
        end
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
          list.size > max_diffs_per_table
        end
        lines << "  (showing first #{max_diffs_per_table} of each mismatch type — re-run after fixing to see remaining)" if truncated

        lines.join("\n")
      end
    end

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

      fail_count = hmis_csv_qa_comparison.new(ds_a_id: ds_a_id, ds_b_id: ds_b_id).run
      exit(1) if fail_count.positive?
    end
  end
end
