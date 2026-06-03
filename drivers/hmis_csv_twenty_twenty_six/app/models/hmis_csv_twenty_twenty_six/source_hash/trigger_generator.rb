###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix
  module SourceHash
    # Single source of truth for the PostgreSQL `source_hash` trigger functions.
    #
    # Generates one `BEFORE INSERT OR UPDATE` trigger function per 2026 importer
    # staging table that computes `source_hash` in the database as the row is
    # written, replacing the per-row Ruby `klass.new(...).calculate_source_hash`
    # in the `pre_process` hot loop.
    #
    # The migration calls `execute function_sql(klass)` / `execute
    # drop_function_sql(klass)` directly — no committed SQL files, no `fx` gem.
    #
    # Canonical serialization (must stay deterministic + GUC-independent):
    #   * column set & order: `hmis_structure(version: '2026').keys` minus :ExportID
    #     (matches the legacy Ruby hash's column set so change-detection semantics
    #     are preserved -- only the byte encoding differs)
    #   * per-type rendering: text as-is, integer ::text, date/timestamp via an
    #     explicit `to_char` mask (independent of DateStyle / TimeZone GUCs)
    #   * each column wrapped in COALESCE(rendered, <NULL sentinel>) and joined with
    #     a field delimiter so NULL vs '' and column boundaries are unambiguous
    #     (bare concat_ws would drop NULLs and allow column-shift collisions)
    #   * hash: encode(sha256(convert_to(<canonical>, 'UTF8')), 'hex')
    module TriggerGenerator
      extend self

      # Control characters chosen because they cannot appear in HMIS CSV data.
      FIELD_DELIMITER = '\x1e' # ASCII RS (record separator) between columns
      NULL_SENTINEL = '\x1f'   # ASCII US (unit separator) standing in for a NULL column

      # Excluded from the hash to match the legacy Ruby `hmis_data.except(:ExportID)`.
      EXCLUDED_COLUMNS = [:ExportID].freeze

      HUD_CSV_VERSION = '2026'

      # The 2026 base importer staging classes that pre_process writes `source_hash` to.
      def staging_classes
        HmisCsvTwentyTwentySix.base_importable_files_map.values.map do |short_name|
          HmisCsvTwentyTwentySix::Importer.const_get(short_name)
        end
      end

      def function_name(klass)
        "source_hash_#{klass.table_name}"
      end

      def trigger_name(klass)
        "set_source_hash_#{klass.table_name}"
      end

      # Ordered [name, type] pairs that feed the hash.
      #
      # Driven by the *live table schema* rather than `hmis_structure` alone: we
      # walk the declared HUD structure order (minus the excluded columns) but
      # keep only columns that actually exist on the table, and take each
      # column's type from the database. This avoids referencing a column the
      # structure declares but the table dropped (e.g. FY2026 Client still lists
      # the retired `HispanicLatinao`) and avoids ever hard-coding a stale list.
      def hash_columns(klass)
        present = klass.column_names.to_set
        klass.hmis_structure(version: HUD_CSV_VERSION).
          except(*EXCLUDED_COLUMNS).
          keys.
          map(&:to_s).
          select { |name| present.include?(name) }.
          map { |name| [name, klass.columns_hash.fetch(name).type] }
      end

      # Columns the UPDATE trigger watches. Identical to the hashed columns: every
      # cleanup transform that can change the hash mutates one of these, while
      # bookkeeping-only updates (dirty_at, clean_at, should_import, processed_as,
      # …) don't pointlessly rehash 1.8M rows.
      def update_of_columns(klass)
        hash_columns(klass).map(&:first)
      end

      # SQL that renders a single column to canonical text, NULL-coalesced.
      def column_expression(name, type)
        quoted = %(NEW."#{name}")
        rendered =
          case type
          when :string
            quoted
          when :integer
            "#{quoted}::text"
          when :date
            "to_char(#{quoted}, 'YYYY-MM-DD')"
          when :datetime
            # timestamp(6) without time zone -> keep microseconds to stay lossless
            "to_char(#{quoted}, 'YYYY-MM-DD HH24:MI:SS.US')"
          else
            raise "Unsupported source_hash column type #{type.inspect} for #{name}"
          end
        "COALESCE(#{rendered}, E'#{NULL_SENTINEL}')"
      end

      def canonical_expression(klass)
        joiner = " || E'#{FIELD_DELIMITER}' ||\n        "
        hash_columns(klass).
          map { |name, type| column_expression(name, type) }.
          join(joiner)
      end

      # Full `CREATE OR REPLACE FUNCTION` body -- the canonical contents of the
      # committed fx `.sql` file for this table.
      def function_sql(klass)
        <<~SQL
          CREATE OR REPLACE FUNCTION #{function_name(klass)}()
          RETURNS trigger AS $$
          BEGIN
            NEW.source_hash := encode(
              sha256(
                convert_to(
                  #{canonical_expression(klass)},
                  'UTF8'
                )
              ),
              'hex'
            );
            RETURN NEW;
          END;
          $$ LANGUAGE plpgsql;
        SQL
      end

      # Raw `CREATE TRIGGER` DDL. UPDATE is scoped to the hashed HUD columns so
      # bookkeeping-only updates skip the rehash.
      def create_trigger_sql(klass)
        columns = update_of_columns(klass).map { |c| %("#{c}") }.join(', ')
        <<~SQL.strip
          CREATE TRIGGER #{trigger_name(klass)}
          BEFORE INSERT OR UPDATE OF #{columns}
          ON #{klass.quoted_table_name}
          FOR EACH ROW
          EXECUTE FUNCTION #{function_name(klass)}()
        SQL
      end

      def drop_trigger_sql(klass)
        "DROP TRIGGER IF EXISTS #{trigger_name(klass)} ON #{klass.quoted_table_name}"
      end

      def drop_function_sql(klass)
        "DROP FUNCTION IF EXISTS #{function_name(klass)}()"
      end
    end
  end
end
