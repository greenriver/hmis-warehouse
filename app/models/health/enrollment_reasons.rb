###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# ### HIPAA Risk Assessment
# Risk: Describes patient enrollments and contains PHI
# Control: PHI attributes documented

require 'roo'
module Health
  class EnrollmentReasons < HealthBase
    include FileContentValidator

    phi_attr :content, Phi::Bulk, 'Enrollment reasons' # contains EDI serialized PHI
    phi_attr :original_filename, Phi::FreeText

    # Remove CarrierWave dependency
    # mount_uploader :file, EnrollmentReasonsFileUploader

    validate :validate_file_content_if_present

    def validate_file_content_if_present
      return if content.blank?

      # Determine file extension from content_type, original_filename, or file attribute
      file_extension = if content_type&.include?('spreadsheet')
        '.xlsx'
      elsif original_filename&.end_with?('.xlsx')
        '.xlsx'
      elsif file&.end_with?('.xlsx')
        '.xlsx'
      elsif content.start_with?([80, 75, 3, 4].pack('C*')) # PK\x03\x04 (ZIP/XLSX magic bytes)
        '.xlsx'
      else
        '.csv'
      end

      allowed_types = if file_extension == '.xlsx'
        ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'application/zip']
      else
        ['text/plain', 'text/csv', 'application/csv', 'application/vnd.ms-excel']
      end

      result = self.class.validate_file_content(
        content,
        content_type,
        allowed_types,
        file_extension,
      )

      return if result[:valid]

      errors.add(:file, result[:error])
    end

    # Alias name to file attribute for compatibility
    def name
      file
    end

    def reasons
      return {} unless content.present?

      @reasons ||= begin
        csv = if content_type.in?(['text/plain', 'text/csv'])
          sheet = ::Roo::CSV.new(StringIO.new(content))
          sheet.parse(headers: true).drop(1) # rubocop:disable Style/IdenticalConditionalBranches
        else
          sheet = ::Roo::Excelx.new(StringIO.new(content).binmode)
          return {} if sheet&.first_row.blank?

          sheet.parse(headers: true).drop(1) # rubocop:disable Style/IdenticalConditionalBranches
        end
        csv.map! { |row| row.transform_keys { |key| key&.gsub(/\W/, '')&.downcase } }
        csv.map { |row| [row['medicaid_id'], row['start_reason_desc']] }.to_h
      end
    end
  end
end
