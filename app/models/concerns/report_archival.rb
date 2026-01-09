###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Concern for report CSV archival functionality
# Provides methods for checking archival status, generating helper methods, and managing CSV backups
# Usage:
#   class MyReport
#     include ReportArchival
#
#     has_many_attached :clients_csv
#
#     def archival_csv_config
#       { clients_csv: { association: :clients } }
#     end
#   end
module ReportArchival
  extend ActiveSupport::Concern

  def self.register_report_type(klass)
    Rails.application.config.report_archival_types << klass.name unless Rails.application.config.report_archival_types.include?(klass.name)
  end

  included do
    # Register this report type for archival
    ReportArchival.register_report_type(self)

    # Override in report models to define CSV structure
    # Returns hash like: { clients_csv: { association: :clients }, ... }
    def archival_csv_config
      {}
    end
  end

  # ============================================================================
  # Archival Status Methods
  # ============================================================================

  def archived?
    # Archived means CSV files exist and are complete
    return false unless archival_metadata.present? && archival_metadata['archived_at'].present?

    archival_complete?
  end

  def purged?
    # Purged means database records have been removed
    archival_metadata.present? && archival_metadata['purged_at'].present?
  end

  def purge_eligible?
    # Check if grace period has expired
    return false unless archival_metadata.present?
    return false if archival_metadata['purged_at'].present? # Already purged

    purge_eligible_at_str = archival_metadata['purge_eligible_at']
    return false unless purge_eligible_at_str

    purge_eligible_at = Time.parse(purge_eligible_at_str)
    purge_eligible_at <= Time.current
  end

  def archival_complete?
    return false unless archival_metadata.present? && archival_metadata['archived_at'].present?

    expected_files = archival_metadata['expected_files'] || []
    return false if expected_files.empty?

    expected_files.all? do |attachment_name|
      send(attachment_name).attached?
    end
  end

  def incomplete_archival?
    return false unless archival_metadata.present? && archival_metadata['archived_at'].present?

    !archival_complete?
  end

  def archival_status
    has_csv = archival_metadata.present? && archival_metadata['archived_at'].present?
    return { archived: false } unless has_csv

    expected_files = archival_metadata['expected_files'] || []
    files_status = expected_files.each_with_object({}) do |attachment_name, hash|
      attachment = send(attachment_name)
      hash[attachment_name] = {
        expected: true,
        attached: attachment.attached?,
        file_count: attachment.attached? ? attachment.count : 0,
      }
    end

    purge_eligible_at_str = archival_metadata['purge_eligible_at']
    purged_at_str = archival_metadata['purged_at']
    grace_period_days = archival_metadata['grace_period_days']

    {
      archived: archived?,
      purged: purged?,
      purge_eligible: purge_eligible?,
      archived_at: archival_metadata['archived_at'],
      purge_eligible_at: purge_eligible_at_str,
      purged_at: purged_at_str,
      grace_period_days: grace_period_days,
      expected_file_count: archival_metadata['expected_file_count'],
      expected_files: expected_files,
      files: files_status,
      complete: archival_complete?,
    }
  end

  def expected_archival_files
    return [] unless archival_metadata.present? && archival_metadata['archived_at'].present?

    archival_metadata['expected_files'] || []
  end

  def update_archival_metadata(key, value)
    current_metadata = archival_metadata || {}
    current_metadata[key] = value
    update_column(:archival_metadata, current_metadata)
  end

  # ============================================================================
  # Archival Actions
  # ============================================================================

  def archive_and_purge!(force: false)
    # Archive if needed
    unless archived? && archival_complete?
      service = Reports::ArchiveReportService.new(self)

      # Reload report to ensure associations are fresh after bulk imports
      reload

      success = service.archive!
      unless success
        error_messages = service.errors.map { |e| e.is_a?(Hash) ? "#{e[:attachment]}: #{e[:error]}" : e.to_s }
        Rails.logger.error("Failed to archive report ##{id} (#{self.class.name}). Errors: #{error_messages.inspect}")
        return {
          success: false,
          errors: ["Failed to archive report before purge: #{error_messages.join(', ')}"],
        }
      end
    end

    # Purge the data
    purge_service = Reports::PurgeArchivedReportDataService.new(self, dry_run: false, force: force)
    purge_service.purge!
  end
end
