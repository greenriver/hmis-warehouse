###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'csv'
require_relative 'constants'

module Reports
  class ArchiveReportService
    attr_reader :report, :errors

    def initialize(report)
      @report = report
      @errors = []
    end

    def eligible?
      # Check if report includes the ReportArchival concern
      return false unless report.respond_to?(:archival_csv_config)

      # Check if archival is configured (non-empty config)
      config = report.archival_csv_config
      return false if config.blank?

      true
    rescue StandardError => e
      Rails.logger.warn("Error checking archival eligibility for report #{report.class.name} ##{report.id}: #{e.message}") if defined?(Rails.logger)
      false
    end

    def archive!
      return false unless eligible?

      # Skip if already archived to avoid re-attaching files (which triggers PurgeJob)
      if report.archived? && report.archival_complete?
        Rails.logger.info("ArchiveReportService: Report ##{report.id} is already archived, skipping")
        return true
      end

      config = report.archival_csv_config
      return false if config.empty?

      expected_files = config.keys.map(&:to_s)
      expected_file_count = expected_files.size

      # Store expected metadata before starting
      update_archival_metadata(
        expected_file_count: expected_file_count,
        expected_files: expected_files,
        archived_at: Time.current.iso8601,
        archived_by_service: self.class.name,
        files: {},
      )

      # Generate and attach CSV files
      config.each do |attachment_name, csv_config|
        # Skip if already attached to avoid triggering PurgeJob
        if report.send(attachment_name).attached?
          Rails.logger.info("ArchiveReportService: #{attachment_name} already attached for report ##{report.id}, skipping")
          update_file_status(attachment_name, attached: true, attached_at: Time.current.iso8601)
          next
        end

        generate_and_attach_csv(attachment_name, csv_config)
        update_file_status(attachment_name, attached: true, attached_at: Time.current.iso8601)
      rescue StandardError => e
        @errors << { attachment: attachment_name, error: e.message }
        update_file_status(attachment_name, attached: false, error: e.message)
      end

      # Mark as complete if all files attached
      if @errors.empty?
        grace_period_days = DEFAULT_ARCHIVAL_GRACE_PERIOD_DAYS
        archived_at = Time.current
        purge_eligible_at = archived_at + grace_period_days.days

        update_archival_metadata(
          complete: true,
          completed_at: archived_at.iso8601,
          grace_period_days: grace_period_days,
          purge_eligible_at: purge_eligible_at.iso8601,
        )

        # Keep database data intact - purge will happen after grace period expires
        Rails.logger.info("Archived report #{report.class.name} ##{report.id} - database data will be purged after #{purge_eligible_at}")
      end

      @errors.empty?
    end

    def complete_archival
      return false unless eligible?
      return false unless report.incomplete_archival?

      config = report.archival_csv_config
      expected_files = archival_metadata['expected_files'] || []

      # Only process files that aren't already attached
      expected_files.each do |attachment_name|
        next if report.send(attachment_name).attached?

        attachment_name_sym = attachment_name.to_sym
        csv_config = config[attachment_name_sym]
        next unless csv_config

        begin
          generate_and_attach_csv(attachment_name_sym, csv_config)
          update_file_status(attachment_name, attached: true, attached_at: Time.current.iso8601)
        rescue StandardError => e
          @errors << { attachment: attachment_name, error: e.message }
          update_file_status(attachment_name, attached: false, error: e.message)
        end
      end

      # Mark as complete if all files attached
      update_archival_metadata(complete: true, completed_at: Time.current.iso8601) if missing_files.empty?

      @errors.empty?
    end

    private

    def generate_and_attach_csv(attachment_name, csv_config)
      # Get data from association
      association_name = csv_config[:association]
      raise "No association specified for #{attachment_name}" unless association_name

      # Ensure report is reloaded to get fresh associations after bulk imports
      report.reload unless report.new_record?
      association = report.send(association_name)
      # Force reload if it's a relation
      association = association.reload if association.is_a?(ActiveRecord::Relation)
      records = association

      # Generate CSV content
      # Handle ActiveRecord::Relation by converting to array
      records_to_csv = if records.is_a?(ActiveRecord::Relation)
        records.to_a
      else
        Array(records)
      end

      # Debug: Log if we're getting empty records
      if records_to_csv.empty?
        Rails.logger.warn("ArchiveReportService: #{attachment_name} has 0 records for report #{report.id}")
        Rails.logger.warn("ArchiveReportService: Association #{csv_config[:association]} returned: #{records.inspect}")
      end

      csv_content = generate_csv(records_to_csv)

      # Debug: Log CSV content size
      Rails.logger.info("ArchiveReportService: Generated #{csv_content.bytesize} bytes of CSV for #{attachment_name} (report #{report.id})")

      # Generate filename
      filename = if csv_config[:filename]
        csv_config[:filename].call
      else
        "#{attachment_name}-#{report.id}.csv"
      end

      # Attach to report
      attachment = report.send(attachment_name)
      attachment.attach(
        io: StringIO.new(csv_content),
        filename: filename,
        content_type: 'text/csv',
      )
    end

    def generate_csv(records)
      return '' if records.blank?

      # Convert ActiveRecord relation to array if needed
      records_array = records.is_a?(ActiveRecord::Relation) ? records.to_a : Array(records)
      return '' if records_array.empty?

      # Get column names from first record
      first_record = records_array.first
      column_names = if first_record.is_a?(ActiveRecord::Base)
        first_record.class.column_names
      elsif first_record.respond_to?(:keys)
        first_record.keys
      else
        first_record.attributes.keys
      end

      # Debug: Log column names and record count
      Rails.logger.debug("ArchiveReportService: Generating CSV with #{column_names.size} columns and #{records_array.size} rows")
      Rails.logger.debug("ArchiveReportService: Column names: #{column_names.inspect}") if column_names.present?

      CSV.generate do |csv|
        csv << column_names
        records_array.each do |record|
          values = if record.is_a?(ActiveRecord::Base)
            column_names.map { |col| record.send(col) }
          elsif record.respond_to?(:[])
            column_names.map { |col| record[col] }
          else
            column_names.map { |col| record.send(col) }
          end
          csv << values
        end
      end
    end

    def update_archival_metadata(updates)
      current_metadata = report.archival_metadata || {}
      report.update_column(:archival_metadata, current_metadata.merge(updates.with_indifferent_access))
    end

    def update_file_status(attachment_name, status_updates)
      current_metadata = report.archival_metadata || {}
      files = current_metadata['files'] || {}
      files[attachment_name] = (files[attachment_name] || {}).merge(status_updates.with_indifferent_access)

      update_archival_metadata(files: files)
    end

    def archival_metadata
      report.archival_metadata || {}
    end

    def missing_files
      expected_files = archival_metadata['expected_files'] || []
      expected_files.reject { |name| report.send(name).attached? }
    end

    def purge_database_data
      purge_service = Reports::PurgeArchivedReportDataService.new(report, dry_run: false)
      result = purge_service.purge!

      if result[:success]
        Rails.logger.info("Purged database data for report #{report.class.name} ##{report.id} after archival")
      else
        # Log errors but don't fail archival if purge fails
        Rails.logger.error("Failed to purge database data for report #{report.class.name} ##{report.id}: #{result[:errors].join(', ')}")
        @errors << { purge: result[:errors] }
      end
    rescue StandardError => e
      # Log errors but don't fail archival if purge fails
      Rails.logger.error("Error purging database data for report #{report.class.name} ##{report.id}: #{e.message}")
      @errors << { purge: e.message }
    end
  end
end
