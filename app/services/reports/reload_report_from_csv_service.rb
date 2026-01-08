###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'report_csv_reader'
require 'csv'
require_relative 'constants'

module Reports
  class ReloadReportFromCsvService
    attr_reader :report, :errors

    def initialize(report)
      @report = report
      @errors = []
    end

    def can_reload?
      return false unless report.present?
      return false unless report.archival_complete?

      # CSV files must exist and be complete
      expected_files = report.archival_metadata&.dig('expected_files') || []
      return false if expected_files.empty?

      expected_files.all? { |name| report.send(name).attached? }
    end

    def reload!
      return { success: false, errors: ['Report not found'] } unless report.present?

      unless can_reload?
        return {
          success: false,
          errors: ['CSV files are not available or archival is incomplete'],
        }
      end

      config = report.archival_csv_config
      return { success: false, errors: ['No archival configuration found'] } if config.empty?

      reloaded_counts = {}
      errors = []

      begin
        # Reload each association from its CSV
        config.each do |attachment_name, csv_config|
          count = reload_association(attachment_name, csv_config)
          reloaded_counts[attachment_name] = count
        rescue StandardError => e
          error_msg = "Failed to reload #{attachment_name}: #{e.message}"
          errors << error_msg
          Rails.logger.error("ReloadReportFromCsvService: #{error_msg}")
          Rails.logger.error(e.backtrace.first(10).join("\n"))
        end

        # If all reloads succeeded, update metadata to restart grace period
        if errors.empty?
          grace_period_days = Reports::DEFAULT_ARCHIVAL_GRACE_PERIOD_DAYS
          reloaded_at = Time.current
          purge_eligible_at = reloaded_at + grace_period_days.days

          update_reload_metadata(
            reloaded_at: reloaded_at.iso8601,
            purge_eligible_at: purge_eligible_at.iso8601,
          )

          Rails.logger.info("Reloaded report #{report.class.name} ##{report.id} - grace period restarted, purge eligible at #{purge_eligible_at}")
        end

        {
          success: errors.empty?,
          reloaded_counts: reloaded_counts,
          errors: errors,
        }
      rescue StandardError => e
        error_msg = "Error reloading report #{report.class.name} ##{report.id}: #{e.message}"
        Rails.logger.error("#{error_msg}\n#{e.backtrace.first(10).join("\n")}")
        {
          success: false,
          errors: [error_msg] + errors,
        }
      end
    end

    def reload_association(attachment_name, csv_config)
      # Read CSV data
      reader = ReportCsvReader.new(report, attachment_name)
      csv_data = reader.all

      Rails.logger.info("ReloadReportFromCsvService: Reading #{csv_data.size} rows from #{attachment_name} for report ##{report.id}")

      return 0 if csv_data.empty?

      # Determine which association/model to reload
      association_name = csv_config[:association]
      raise "No association specified for #{attachment_name}" unless association_name

      # Get the model class - use reflection to get the class even if association is empty
      model_class = report.class.reflect_on_association(association_name)&.klass
      raise "Could not determine model class for association #{association_name}" unless model_class

      Rails.logger.info("ReloadReportFromCsvService: Reloading into #{model_class.name} for #{attachment_name}")

      # Get valid column names for the model
      valid_columns = model_class.column_names.to_set
      # Exclude id from inserts - let database auto-generate new IDs
      # This avoids primary key conflicts and sequence issues
      columns_to_exclude = ['id'].to_set

      # Convert CSV data to model attributes
      now = Time.current
      records = csv_data.map do |row|
        # Convert symbol keys to model attributes
        attributes = row.transform_keys(&:to_s)
        # Ensure report_id is set (must be done before filtering)
        attributes['report_id'] = report.id
        # Ensure deleted_at is nil (for acts_as_paranoid models)
        attributes['deleted_at'] = nil if valid_columns.include?('deleted_at')
        # Set timestamps if columns exist
        attributes['created_at'] = now if valid_columns.include?('created_at') && attributes['created_at'].blank?
        attributes['updated_at'] = now if valid_columns.include?('updated_at') && attributes['updated_at'].blank?
        # Only include columns that exist in the model and aren't excluded
        filtered_attributes = attributes.select { |key, _| valid_columns.include?(key) && !columns_to_exclude.include?(key) }
        # Ensure report_id is included (double-check)
        filtered_attributes['report_id'] = report.id if valid_columns.include?('report_id')
        # Convert string values to appropriate types based on model columns
        # Use model's attribute assignment to handle type conversion
        model_instance = model_class.new
        filtered_attributes.each do |key, value|
          model_instance.send("#{key}=", value) if model_instance.respond_to?("#{key}=")
        end
        final_attributes = model_instance.attributes
        # Remove id if it was set by the model (from CSV data)
        final_attributes.delete('id')
        # Final safety check: ensure report_id is in the final attributes
        final_attributes['report_id'] = report.id if valid_columns.include?('report_id')
        # Explicitly set deleted_at to nil for acts_as_paranoid models (insert_all needs this)
        final_attributes['deleted_at'] = nil if valid_columns.include?('deleted_at')
        final_attributes
      end

      # Verify report_id is present in all records
      missing_report_id = records.any? { |r| r['report_id'].blank? || r['report_id'] != report.id }
      if missing_report_id
        Rails.logger.error('ReloadReportFromCsvService: WARNING - Some records are missing report_id!')
        Rails.logger.error("Sample record: #{records.first&.inspect}")
      end

      Rails.logger.info("ReloadReportFromCsvService: Converted #{records.size} records, sample keys: #{records.first&.keys&.first(5)&.inspect}, report_id present: #{records.first&.dig('report_id') == report.id}")

      # Bulk insert records using Rails' insert_all
      # Delete existing records for this report first to avoid duplicates
      model_class.where(report_id: report.id).delete_all

      # Insert in batches
      return 0 if records.empty?

      # Get all columns that appear in any record
      all_keys = records.flat_map(&:keys).uniq
      # Ensure all records have the same columns (fill missing with nil)
      normalized_records = records.map do |record|
        normalized = all_keys.each_with_object({}) do |key, hash|
          hash[key] = record[key]
        end
        # Final safety check: ensure report_id is always set
        normalized['report_id'] = report.id if valid_columns.include?('report_id')
        # Explicitly set deleted_at to nil for acts_as_paranoid models
        normalized['deleted_at'] = nil if valid_columns.include?('deleted_at')
        normalized
      end

      normalized_records.each_slice(5_000) do |batch|
        # Log sample record before insert
        if batch.first
          sample = batch.first
          Rails.logger.info("ReloadReportFromCsvService: Inserting batch - sample record keys: #{sample.keys.inspect}")
          Rails.logger.info("ReloadReportFromCsvService: Sample report_id: #{sample['report_id']}, deleted_at: #{sample['deleted_at'].inspect}")
        end

        inserted = model_class.insert_all(batch)
        Rails.logger.info("ReloadReportFromCsvService: Inserted batch of #{batch.size} records for #{attachment_name}, insert_all returned: #{inserted.inspect}")
      rescue StandardError => e
        Rails.logger.error("Failed to insert batch for #{attachment_name}: #{e.message}")
        Rails.logger.error("Batch size: #{batch.size}, Columns: #{batch.first&.keys&.inspect}")
        Rails.logger.error("Sample record: #{batch.first&.inspect}")
        raise
      end

      # Verify records were inserted (check both scoped and unscoped)
      inserted_count_scoped = model_class.where(report_id: report.id).count
      inserted_count_unscoped = model_class.unscoped.where(report_id: report.id).count
      Rails.logger.info("ReloadReportFromCsvService: Verified #{inserted_count_scoped} records (scoped) / #{inserted_count_unscoped} records (unscoped) in database for #{attachment_name} (report ##{report.id})")

      if inserted_count_scoped != inserted_count_unscoped
        soft_deleted = model_class.unscoped.where(report_id: report.id).where.not(deleted_at: nil).count
        Rails.logger.warn("ReloadReportFromCsvService: WARNING - #{soft_deleted} records have deleted_at set (should be 0)")
      end

      records.size
    end

    private

    def update_reload_metadata(updates)
      current_metadata = report.archival_metadata || {}
      # Clear purged_at since data is now back in database
      # Reset purge_eligible_at to restart grace period
      updated_metadata = current_metadata.merge(
        updates.with_indifferent_access.merge(
          'purged_at' => nil,
        ),
      )
      report.update_column(:archival_metadata, updated_metadata)
    end
  end
end
