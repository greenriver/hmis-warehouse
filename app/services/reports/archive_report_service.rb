###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'csv'
require 'tempfile'
require 'stringio'

module Reports
  # Get the archival grace period in days from AppConfigProperty, defaulting to 60
  def self.archival_grace_period_days
    property = AppConfigProperty.find_by(key: 'reports/archival_grace_period_days')
    return 60 if property.nil?

    value = property.value
    # AppConfigProperty stores values as JSON, so numbers are already parsed
    # Handle both numeric values and string representations
    value.to_i
  end

  class ArchiveReportService
    attr_reader :report, :errors

    def initialize(report)
      @report = report
      @errors = []
    end

    def config
      @config ||= report.archival_csv_config
    end

    def eligible?
      # Check if report includes the ReportArchival concern
      return false unless report.respond_to?(:archival_csv_config)

      # Check if archival is configured (non-empty config)
      return false if config.blank?

      true
    end

    def archive!
      return false unless eligible?

      # Skip if already archived to avoid re-attaching files (which triggers PurgeJob)
      if report.archived?
        Rails.logger.info("ArchiveReportService: Report ##{report.id} is already archived, skipping")
        return true
      end

      # Capture original timestamp at the start of archival process
      original_updated_at = report.updated_at
      Rails.logger.info("ArchiveReportService: Original updated_at: #{original_updated_at}")

      begin
        # Use existing expected_files from metadata if present, otherwise calculate from config
        existing_metadata = report.archival_metadata || {}
        expected_files = existing_metadata['expected_files'] || config.keys.map(&:to_s)
        expected_file_count = expected_files.size

        # Generate and attach CSV files (only for expected files)
        expected_files.each do |attachment_name_str|
          attachment_name = attachment_name_str.to_sym
          csv_config = config[attachment_name]
          next unless csv_config # Skip if not in config (shouldn't happen, but be safe)

          # Skip if already attached
          if report.send(attachment_name).attached?
            Rails.logger.info("ArchiveReportService: #{attachment_name} already attached for report ##{report.id}, skipping")
            update_file_status(attachment_name, { attached: true, attached_at: Time.current.iso8601 })
            next
          end

          generate_and_attach_csv(attachment_name, csv_config)
          update_file_status(attachment_name, { attached: true, attached_at: Time.current.iso8601 })
        rescue StandardError => e
          @errors << { attachment: attachment_name, error: e.message }
          update_file_status(attachment_name, { attached: false, error: e.message })
        end

        return false unless @errors.empty?

        archived_at = Time.current
        update_archival_metadata({
                                   expected_file_count: expected_file_count,
                                   expected_files: expected_files,
                                   archived_at: archived_at.iso8601,
                                 })
      ensure
        # Always restore the original timestamp, regardless of success or failure
        report.update_column(:updated_at, original_updated_at) if report.updated_at != original_updated_at
      end

      Rails.logger.info("Archived report #{report.class.name} ##{report.id}")
    end

    private

    def generate_and_attach_csv(attachment_name, csv_config)
      # Get data from association
      association_name = csv_config[:association]
      raise "No association specified for #{attachment_name}" unless association_name

      association = report.send(association_name)

      # Generate filename
      filename = if csv_config[:filename]
        csv_config[:filename].call
      else
        "#{attachment_name}-#{report.class.name.underscore}-#{report.id}.csv"
      end

      # Generate CSV to temp file (streams directly to disk)
      temp_file = Tempfile.new(['archive', '.csv'])
      begin
        generate_csv_to_file(association, attachment_name, temp_file.path)

        attachment = report.send(attachment_name)

        # Verify file is not empty before opening
        raise "Generated CSV is empty for #{attachment_name}" if File.size(temp_file.path) == 0

        # Open file handle and keep it open until after save completes
        # Active Storage reads the file during attach and save, so we need the handle to stay open
        file_handle = File.open(temp_file.path, 'rb')
        begin
          attachment.attach(
            io: file_handle,
            filename: filename,
            content_type: 'text/csv',
          )

          # Ignore validation here. We are only persisting the csv attachements for existing reports, and
          # some older reports may be in invalid states. We still want to archive their data.
          report.save(validate: false)
        ensure
          file_handle.close
        end
      ensure
        temp_file.close
        temp_file.unlink # Delete temp file
      end
    end

    def generate_csv_to_file(association, _attachment_name, file_path)
      # Get column names from the association's model class
      model_class = association.klass
      column_names = model_class.column_names

      # Stream CSV directly to file
      CSV.open(file_path, 'wb') do |csv|
        csv << column_names

        # Process in batches to avoid memory issues
        association.find_in_batches(batch_size: 1000) do |batch|
          batch.each do |record|
            values = column_names.map { |col| record.send(col) }
            csv << values
          end
        end
      end
    end

    def update_archival_metadata(updates)
      current_metadata = report.archival_metadata || {}
      report.update_column(
        :archival_metadata,
        current_metadata.merge(updates.with_indifferent_access),
      )
    end

    def update_file_status(attachment_name, status_updates)
      current_metadata = report.archival_metadata || {}
      files = current_metadata['files'] || {}
      files[attachment_name] = (files[attachment_name] || {}).merge(status_updates.with_indifferent_access)

      update_archival_metadata({ files: files })
    end
  end
end
