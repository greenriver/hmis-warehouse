###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# ### HIPAA Risk Assessment
# Risk: Indirectly relates to a patient. Binary data may contain PHI
# Control: PHI attributes documented
module Health::CpMembers
  class FileBase < ::HealthBase
    include FileContentValidator
    acts_as_paranoid

    self.table_name = :cp_member_files

    phi_attr :file, Phi::FreeText, 'Name of file'
    phi_attr :content, Phi::FreeText, 'Content of file'

    belongs_to :user, optional: true

    # Remove CarrierWave dependency
    # mount_uploader :file, MemberRosterFileUploader

    validate :validate_file_content_if_present

    def validate_file_content_if_present
      return if content.blank?

      # For CP Roster files, content is directly assigned in the controller
      # Validate it matches CSV format
      file_extension = '.csv'
      allowed_types = ['text/plain', 'text/csv', 'application/csv', 'application/vnd.ms-excel']

      result = self.class.validate_file_content(
        content,
        nil, # No claimed content type since content is directly assigned
        allowed_types,
        file_extension,
      )

      return if result[:valid]

      errors.add(:file, result[:error])
    end

    # Helper method for controllers to get filename
    def file_identifier
      file
    end

    def parse
      return false unless check_header

      CSV.parse(content, headers: true) do |row|
        model_row = row.to_h
        model_row[:roster_file_id] = id

        model.create(model_row)
      end
      return true
    end

    def label
      type
    end

    def columns
      {}
    end

    def entries
      []
    end

    private def check_header
      incoming = CSV.parse(content.lines.first).flatten.map { |m| m&.strip }
      expected = parsed_expected_header.map { |m| m&.strip }
      # You can update the header string with File.read('path/to/file.csv').lines.first
      # Using CSV parse in case the quoting styles differ
      return true if incoming == expected

      Rails.logger.error (incoming - expected).inspect
      Rails.logger.error (expected - incoming).inspect

      return false
    end

    private def parsed_expected_header
      CSV.parse(expected_header).flatten
    end

    private def model
      raise NotImplementedError
    end

    private def expected_header
      raise NotImplementedError
    end
  end
end
