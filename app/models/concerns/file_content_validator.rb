###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module FileContentValidator
  extend ActiveSupport::Concern

  class_methods do
    def validate_file_content(file_content, claimed_content_type, allowed_types, file_extension)
      return { valid: false, error: 'No file content provided' } if file_content.blank?

      # Check file size first
      if file_content.bytesize > 25.megabytes
        return {
          valid: false,
          error: "File is too large (#{(file_content.bytesize / 1.megabyte).round(1)} MB). Maximum size is 25 MB.",
        }
      end

      # Write content to temporary file for Marcel to analyze
      require 'tempfile'
      temp_file = Tempfile.new(['upload', file_extension])
      begin
        temp_file.binmode
        temp_file.write(file_content)
        temp_file.rewind

        # Use Marcel to detect MIME type from the actual file content (without filename)
        detected_type = Marcel::MimeType.for(temp_file.path)

        # Marcel correctly detects XLSX files as application/zip since they are ZIP archives
        # We should accept this and normalize it to the expected type
        detected_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' if detected_type == 'application/zip' && file_extension.downcase == '.xlsx'

        # If Marcel can't detect the type from content, it returns application/octet-stream
        # In that case, we need to validate the magic bytes manually for security
        if detected_type == 'application/octet-stream'
          # Validate magic bytes based on file extension
          unless valid_magic_bytes?(file_content, file_extension)
            return {
              valid: false,
              error: "File content does not match the expected format for #{file_extension.sub('.', '').upcase} files. Please upload a valid #{file_extension.sub('.', '').upcase} file.",
            }
          end
          # If magic bytes are valid, we can trust the file type
          detected_type = infer_type_from_extension(file_extension)
        end

        unless allowed_types.include?(detected_type)
          return {
            valid: false,
            error: "File appears to be #{detected_type}, but #{file_extension.sub('.', '').upcase} files are required. Please upload a valid #{file_extension.sub('.', '').upcase} file.",
          }
        end

        # If a claimed content type was provided, verify it's reasonable
        if claimed_content_type.present?
          claimed_type = claimed_content_type.downcase
          unless allowed_types.include?(claimed_type)
            return {
              valid: false,
              error: "Claimed file type '#{claimed_content_type}' is not supported. Please upload a #{file_extension.sub('.', '').upcase} file.",
            }
          end
        end

        { valid: true, detected_type: detected_type }
      ensure
        temp_file.close
        temp_file.unlink
      end
    end

    private

    def valid_magic_bytes?(file_content, file_extension)
      case file_extension.downcase
      when '.csv'
        # CSV files should contain commas and newlines
        file_content.include?(',') && file_content.include?("\n")
      when '.xlsx'
        # XLSX files start with PK\x03\x04 (ZIP format)
        # Use proper binary string: [80, 75, 3, 4].pack('C*')
        file_content.start_with?([80, 75, 3, 4].pack('C*'))
      when '.xls'
        # XLS files have specific Excel magic bytes
        # Use proper binary string: [208, 207, 17, 224, 161, 177, 26, 225].pack('C*')
        file_content.start_with?([208, 207, 17, 224, 161, 177, 26, 225].pack('C*'))
      when '.pdf'
        # PDF files start with %PDF
        file_content.start_with?('%PDF')
      when '.txt', '.edi'
        # EDI files (820, 834, 271, 999) should start with ISA segment
        # These are plain text files, so we just verify they contain printable text
        file_content.start_with?('ISA')
      else
        false
      end
    end

    def infer_type_from_extension(file_extension)
      case file_extension.downcase
      when '.csv'
        'text/csv'
      when '.xlsx'
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      when '.xls'
        'application/vnd.ms-excel'
      when '.pdf'
        'application/pdf'
      when '.txt', '.edi'
        'text/plain'
      else
        'application/octet-stream'
      end
    end
  end
end
