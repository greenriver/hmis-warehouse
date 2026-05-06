###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'csv'
require 'tempfile'

module HudReports
  # Archives a HudReports::ReportInstance by streaming each associated table to
  # a CSV and attaching it via Active Storage.
  #
  # Unlike Reports::ArchiveReportService (SimpleReports), this reads scope lambdas
  # from archival_csv_config rather than association names. This allows scoping
  # complex tables that have no direct report_instance_id FK.
  #
  # Atomicity: archive! is intentionally NOT wrapped in a DB transaction. Active
  # Storage uploads are external side effects that a transaction cannot roll back —
  # doing so would orphan files in S3 while losing the metadata that references
  # them. Instead, recovery relies on idempotency: archive! skips already-attached
  # files and only sets archived_at after all files succeed. A partial run can
  # always be safely retried.
  class ArchiveReportService
    attr_reader :report, :errors

    def initialize(report)
      @report = report
      @errors = []
    end

    def archive!
      config = report.archival_csv_config
      return false if config.blank?
      return true if report.archived?

      original_updated_at = report.updated_at

      begin
        expected_files = config.keys.map(&:to_s)
        update_archival_metadata('expected_files', expected_files)
        update_archival_metadata('expected_file_count', expected_files.size)

        # Persist the generator class name so archival_generator_klass can resolve
        # it by constant rather than by report_name string, surviving future renames.
        generator_klass = report.archival_generator_klass
        update_archival_metadata('generator_class', generator_klass.name) if generator_klass

        config.each do |attachment_name, entry|
          attachment = report.send(attachment_name)
          if attachment.attached?
            update_file_status(attachment_name, attached: true, attached_at: Time.current.iso8601)
            next
          end

          generate_and_attach_csv(attachment_name, entry)
          update_file_status(attachment_name, attached: true, attached_at: Time.current.iso8601)
        rescue StandardError => e
          @errors << { attachment: attachment_name, error: e.message }
          update_file_status(attachment_name, attached: false, error: e.message)
        end

        return false if @errors.any?

        update_archival_metadata('archived_at', Time.current.iso8601)
        Rails.logger.info("HudReports::ArchiveReportService: Archived report ##{report.id}")
        true
      ensure
        report.reload
        report.update_column(:updated_at, original_updated_at) if report.updated_at != original_updated_at
      end
    end

    private

    def generate_and_attach_csv(attachment_name, entry)
      relation = entry[:scope].call
      model_class = relation.klass
      column_names = model_class.column_names
      filename = entry[:filename].call

      # JSON/JSONB columns need their string values JSON-encoded in the CSV so they
      # survive the JSON.parse round-trip in the restore service. Without this,
      # ActiveRecord::Type::Json#deserialize("CocCode") raises JSON::ParserError and
      # silently returns nil, wiping any string stored in a jsonb column.
      json_column_names = model_class.attribute_types.
        select { |_, t| [:json, :jsonb].include?(t.type) }.
        keys.to_set

      Tempfile.create(['hud_archive', '.csv']) do |temp_file|
        CSV.open(temp_file.path, 'wb') do |csv|
          csv << column_names
          relation.find_in_batches(batch_size: 1_000) do |batch|
            batch.each do |record|
              csv << column_names.map { |col| csv_value(record[col], json: json_column_names.include?(col)) }
            end
          end
        end

        File.open(temp_file.path, 'rb') do |file_handle|
          report.send(attachment_name).attach(
            io: file_handle,
            filename: filename,
            content_type: 'text/csv',
          )
          report.save(validate: false)
        end
      end
    end

    # Serialize a single cell value for CSV storage.
    #
    # For JSON/JSONB columns (json: true), any Ruby value must be JSON-encoded
    # because the restore path calls ActiveRecord::Type::Json#deserialize on each
    # cell. That method calls JSON.parse, so:
    #   - Hash/Array   → must be JSON (already handled for non-json cols too)
    #   - String       → must be wrapped in quotes: "CocCode" → '"CocCode"'
    #                    otherwise JSON.parse("CocCode") raises and returns nil
    #   - Integer/Float/nil → already valid JSON literals; pass through as-is
    def csv_value(value, json: false)
      return value.to_json if value.is_a?(Hash) || value.is_a?(Array)
      return value.to_json if json && value.is_a?(String)

      value
    end

    def update_archival_metadata(key, value)
      current = report.archival_metadata || {}
      report.update_column(:archival_metadata, current.merge(key.to_s => value))
    end

    def update_file_status(attachment_name, status)
      current = report.archival_metadata || {}
      files = current['files'] || {}
      files[attachment_name.to_s] = (files[attachment_name.to_s] || {}).merge(status.stringify_keys)
      update_archival_metadata('files', files)
    end
  end
end
