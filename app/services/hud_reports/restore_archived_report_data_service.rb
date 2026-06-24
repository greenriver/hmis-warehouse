###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'report_csv_reader'

module HudReports
  # Restores a purged HudReports::ReportInstance from its CSV archives.
  #
  # Restores in reverse delete_order (highest first = report_cells first, universe_members last)
  # so that FK-like references exist before referencing records are inserted.
  # Uses INSERT ... ON CONFLICT (id) DO NOTHING for idempotent restoration.
  # Resets PK sequences after all tables are restored.
  class RestoreArchivedReportDataService
    attr_reader :report, :errors

    def initialize(report)
      @report = report
      @errors = []
    end

    def can_restore?
      return false unless report.present? && report.archived?

      expected_files.all? { |name| report.send(name).attached? }
    end

    def restore!
      return { success: false, errors: ['Cannot restore: report not archived or files missing'] } unless can_restore?

      config = report.archival_csv_config
      return { success: false, errors: ['No archival config found'] } if config.blank?

      original_updated_at = report.updated_at
      restored_counts = {}

      begin
        report.class.transaction do
          # Restore in reverse delete_order (highest delete_order first)
          sorted_entries = config.sort_by { |_k, v| -v[:delete_order] }

          sorted_entries.each do |attachment_name, entry|
            next unless expected_files.include?(attachment_name.to_s)
            next unless report.send(attachment_name).attached?

            count = restore_from_csv(attachment_name, entry)
            restored_counts[attachment_name] = count
          rescue StandardError => e
            raise e.class, "#{attachment_name}: #{e.message}", e.backtrace
          end

          # reset_sequences uses DDL (setval). In PostgreSQL DDL *is* transactional,
          # so a rollback will undo the sequence reset — the correct behaviour here.
          reset_sequences(config)
          clear_purged_at
        end

        Rails.logger.info("HudReports::RestoreArchivedReportDataService: Restored report ##{report.id}: #{restored_counts.inspect}")
      rescue StandardError => e
        @errors << "Failed to restore: #{e.message}"
        Rails.logger.error(
          "HudReports::RestoreArchivedReportDataService: #{@errors.last}\n#{e.backtrace.first(5).join("\n")}",
        )
      ensure
        # Guard with rescue nil: if the DB connection was the cause of the rollback,
        # these calls would raise a second exception and swallow the original error.
        report.reload rescue nil # rubocop:disable Style/RescueModifier
        report.update_column(:updated_at, original_updated_at) if report.updated_at != original_updated_at rescue nil # rubocop:disable Style/RescueModifier
      end

      { success: @errors.empty?, restored_counts: restored_counts, errors: @errors }
    end

    private

    def expected_files
      @expected_files ||= report.archival_metadata&.dig('expected_files') || []
    end

    def restore_from_csv(attachment_name, entry)
      relation = entry[:scope].call
      model_class = relation.klass
      valid_columns = model_class.column_names.to_set

      # json/jsonb columns need special handling in upsert_all:
      #   Type::Json#serialize always calls ActiveSupport::JSON.encode(value).
      #   Passing a CSV String causes double-encoding:
      #     String → encode → JSON string → SQL-quoted → PostgreSQL stores a
      #     JSON *string* wrapping the object rather than the object itself.
      #   Fix: parse the CSV string as JSON first → Ruby value → upsert_all
      #   serializes it exactly once. ✓
      #
      #   Use t.type (:json/:jsonb) rather than is_a?(ActiveRecord::Type::Json)
      #   because the PG OID classes don't always share the same inheritance chain
      #   across Rails versions.
      json_columns = model_class.attribute_types.
        select { |_, t| [:json, :jsonb].include?(t.type) }.
        keys.to_set

      reader = ReportCsvReader.new(report, attachment_name)
      total = 0

      reader.batch_read(batch_size: 5_000) do |batch|
        records = batch.map do |row|
          row_str = row.transform_keys(&:to_s)

          instance = model_class.new
          row_str.each do |col, value|
            next unless valid_columns.include?(col) && instance.respond_to?(:"#{col}=")
            next if json_columns.include?(col)

            instance.send(:"#{col}=", value)
          end
          attrs = instance.attributes.select { |k, _| valid_columns.include?(k) }

          # Replace json column values with their deserialized Ruby types.
          # Use explicit JSON.parse rather than type.deserialize: the AR Json type
          # swallows JSON::ParserError and returns nil, which silently wipes string
          # values (e.g. "CocCode") that aren't valid JSON literals. Archives
          # created before this fix contain bare strings; fall back to the raw
          # CSV value so they restore correctly without needing re-archiving.
          json_columns.each do |col|
            next unless valid_columns.include?(col) && row_str.key?(col)

            raw = row_str[col]
            attrs[col] = if raw.nil? || raw == ''
              nil
            else
              begin
                ActiveSupport::JSON.decode(raw)
              rescue JSON::ParserError
                raw
              end
            end
          end

          attrs
        end

        normalized = normalize_batch(records)
        model_class.upsert_all(normalized, unique_by: :id) if normalized.any?
        total += normalized.size
      end

      total
    end

    def normalize_batch(records)
      return [] if records.empty?

      all_keys = records.flat_map(&:keys).uniq
      records.map { |r| all_keys.each_with_object({}) { |k, h| h[k] = r[k] } }
    end

    def reset_sequences(config)
      config.each_value do |entry|
        model_class = entry[:scope].call.klass
        table_name = model_class.table_name
        conn = model_class.connection

        # Use GREATEST(..., 1) because setval requires a value >= the sequence minimum (1).
        # Wrap in a SAVEPOINT so a failure does not abort the surrounding transaction.
        conn.transaction(requires_new: true) do
          conn.execute(
            "SELECT setval(pg_get_serial_sequence('#{table_name}', 'id'), GREATEST(COALESCE(MAX(id), 0), 1)) FROM #{table_name}",
          )
        end
      rescue StandardError => e
        Rails.logger.warn("HudReports restore: could not reset sequence for #{table_name}: #{e.message}")
      end
    end

    # Clears purged_at from metadata so the report is no longer considered purged.
    # CSV files and archived_at are intentionally preserved: the restored DB rows
    # match the CSVs exactly, so the integrity check will pass if the report is
    # purged again — no re-archiving needed.
    def clear_purged_at
      current = report.archival_metadata || {}
      report.update_column(:archival_metadata, current.except('purged_at'))
    end
  end
end
