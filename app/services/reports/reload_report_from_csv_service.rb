###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'report_csv_reader'
require 'csv'
require_relative 'archive_report_service'

module Reports
  class ReloadReportFromCsvService
    attr_reader :report, :errors

    def initialize(report)
      @report = report
      @errors = []
    end

    def can_reload?
      return false unless report.present?
      return false unless report.archived?

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

      # Only reload associations that were actually archived (from expected_files)
      expected_files = report.archival_metadata&.dig('expected_files') || []
      return { success: false, errors: ['No expected files found in archival metadata'] } if expected_files.empty?

      # Filter config to only include expected files
      config_to_reload = config.select { |attachment_name, _| expected_files.include?(attachment_name.to_s) }
      return { success: false, errors: ['No matching archival configuration found for expected files'] } if config_to_reload.empty?

      reload_associations(config_to_reload)
    end

    def reload_association(attachment_name, csv_config)
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
      columns_to_exclude = ['id'].to_set

      # Delete existing records first to ensure all data is coming from the CSV
      model_class.where(report_id: report.id).delete_all

      # Stream CSV and insert in batches to avoid loading everything into memory
      reader = ReportCsvReader.new(report, attachment_name)
      now = Time.current
      total_rows = 0

      reader.batch_read(batch_size: 5_000) do |csv_batch|
        # Process batch of CSV rows into model attributes
        processed_batch = csv_batch.map do |row|
          total_rows += 1

          # Convert CSV row to model attributes
          attributes = row.transform_keys(&:to_s)
          # Filter to only include valid columns and exclude id
          filtered_attributes = attributes.select { |key, _| valid_columns.include?(key) && !columns_to_exclude.include?(key) }
          # Set required fields
          filtered_attributes['report_id'] = report.id if valid_columns.include?('report_id')
          filtered_attributes['deleted_at'] = nil if valid_columns.include?('deleted_at')
          # Set timestamps if columns exist and not already set
          filtered_attributes['created_at'] = now if valid_columns.include?('created_at') && filtered_attributes['created_at'].blank?
          filtered_attributes['updated_at'] = now if valid_columns.include?('updated_at') && filtered_attributes['updated_at'].blank?

          # Convert string values to appropriate types using model
          model_instance = model_class.new
          filtered_attributes.each do |key, value|
            model_instance.send("#{key}=", value) if model_instance.respond_to?("#{key}=")
          end
          final_attributes = model_instance.attributes
          final_attributes.delete('id')

          final_attributes
        end

        # Insert the processed batch
        insert_batch(model_class, processed_batch, attachment_name)
      end

      Rails.logger.info("ReloadReportFromCsvService: Processed #{total_rows} rows from #{attachment_name} for report ##{report.id}")

      # Verify records were inserted
      inserted_count_scoped = model_class.where(report_id: report.id).count
      inserted_count_unscoped = model_class.unscoped.where(report_id: report.id).count
      Rails.logger.info("ReloadReportFromCsvService: Verified #{inserted_count_scoped} records (scoped) / #{inserted_count_unscoped} records (unscoped) in database for #{attachment_name} (report ##{report.id})")

      if inserted_count_scoped != inserted_count_unscoped
        soft_deleted = model_class.unscoped.where(report_id: report.id).where.not(deleted_at: nil).count
        Rails.logger.warn("ReloadReportFromCsvService: WARNING - #{soft_deleted} records have deleted_at set (should be 0)")
      end

      total_rows
    end

    private

    def insert_batch(model_class, batch, attachment_name)
      return if batch.empty?

      # Normalize batch records to have same columns
      all_keys = batch.flat_map(&:keys).uniq
      normalized_batch = batch.map do |record|
        all_keys.each_with_object({}) { |key, hash| hash[key] = record[key] }
      end

      # Log sample record before insert
      if normalized_batch.first
        sample = normalized_batch.first
        Rails.logger.info("ReloadReportFromCsvService: Inserting batch - sample record keys: #{sample.keys.inspect}")
        Rails.logger.info("ReloadReportFromCsvService: Sample report_id: #{sample['report_id']}, deleted_at: #{sample['deleted_at'].inspect}")
      end

      inserted = model_class.insert_all(normalized_batch)
      Rails.logger.info("ReloadReportFromCsvService: Inserted batch of #{normalized_batch.size} records for #{attachment_name}, insert_all returned: #{inserted.inspect}")
    rescue StandardError => e
      Rails.logger.error("Failed to insert batch for #{attachment_name}: #{e.message}")
      Rails.logger.error("Batch size: #{batch.size}, Columns: #{batch.first&.keys&.inspect}")
      Rails.logger.error("Sample record: #{batch.first&.inspect}")
      raise
    end

    def reload_associations(config_to_reload)
      reloaded_counts = {}
      errors = []

      # Reload report from database to ensure we have current updated_at value
      report.reload
      # Capture original updated_at before any operations
      original_updated_at = report.updated_at

      begin
        # Reload each association from its CSV
        config_to_reload.each do |attachment_name, csv_config|
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
          grace_period_days = Reports.archival_grace_period_days
          reloaded_at = Time.current
          purge_eligible_at = reloaded_at + grace_period_days.days

          update_reload_metadata(
            reloaded_at: reloaded_at.iso8601,
            purge_eligible_at: purge_eligible_at.iso8601,
          )

          Rails.logger.info("Reloaded report #{report.class.name} ##{report.id} - grace period restarted, purge eligible at #{purge_eligible_at}")
        end
      ensure
        # Reload report from database to get current updated_at value before comparing
        report.reload
        # Always restore the original timestamp, regardless of success or failure
        report.update_column(:updated_at, original_updated_at) if report.updated_at != original_updated_at
      end

      {
        success: errors.empty?,
        reloaded_counts: reloaded_counts,
        errors: errors,
      }
    end

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
