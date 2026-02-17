###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# ### HIPAA Risk Assessment
# Risk: Indirectly relates to a patient. Binary data may contain PHI
# Control: PHI attributes documented
module Health
  class HealthFile < HealthBase
    include NotifierConfig
    include FileContentValidator
    acts_as_paranoid

    phi_attr :name, Phi::FreeText, 'Name of health file'
    phi_attr :content, Phi::FreeText, 'Content of health file'
    phi_attr :note, Phi::FreeText, 'Notes on health file'

    belongs_to :user, optional: true
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true

    # Remove CarrierWave dependency
    # mount_uploader :file, HealthFileUploader

    # Virtual attributes to receive uploaded file from form
    attr_accessor :file
    attr_accessor :file_cache

    validate :validate_uploaded_file_content

    # Handle file_cache to preserve uploads between form submissions
    before_validation :process_file_cache

    def validate_uploaded_file_content
      return if content.blank? && file.blank?

      # Skip validation if we already have content stored (e.g., on update)
      return if content.present? && file.blank?

      # Validate newly uploaded file
      return unless file.present?

      file_content = file.respond_to?(:read) ? file.read : file
      file.rewind if file.respond_to?(:rewind)

      file_extension = File.extname(file.respond_to?(:original_filename) ? file.original_filename : name || '.pdf')
      claimed_content_type = file.respond_to?(:content_type) ? file.content_type : nil

      allowed_types = ['application/pdf']
      result = self.class.validate_file_content(
        file_content,
        claimed_content_type,
        allowed_types,
        file_extension,
      )

      return if result[:valid]

      errors.add(:file, 'must be a valid PDF')
    end

    def title
      self.class.model_name.human
    end

    def signature
      return nil
    end

    def valid_for_current_enrollment
      return nil unless client.patient&.enrollment_start_date.present?

      signature.present? && signature > client.patient.enrollment_start_date || signature.blank? && created_at > client.patient.enrollment_start_date
    end

    def valid_for_contributing_enrollment
      return nil unless client.patient

      client.patient.contributed_enrollment_ranges.each do |range|
        return true if range.cover?(signature)
      end

      return false
    end

    def set_calculated!(user_id, client_id)
      self.user_id ||= user_id
      self.client_id ||= client_id

      # Handle file upload without CarrierWave
      if file.present?
        file_content = file.respond_to?(:read) ? file.read : file
        file.rewind if file.respond_to?(:rewind)

        if file_content.present?
          # Validate file content BEFORE setting attributes
          file_extension = File.extname(file.respond_to?(:original_filename) ? file.original_filename : 'file.pdf')
          allowed_types = ['application/pdf']
          result = self.class.validate_file_content(
            file_content,
            file.respond_to?(:content_type) ? file.content_type : nil,
            allowed_types,
            file_extension,
          )

          # If validation fails, add error and return without setting content
          unless result[:valid]
            errors.add(:file, 'must be a valid PDF')
            return false
          end

          # Validation passed, set attributes
          self.content = file_content
          self.size = file_content.bytesize
          self.name = file.respond_to?(:original_filename) ? file.original_filename : 'uploaded_file.pdf'
          self.content_type = result[:detected_type]

          # Set file_cache for form resubmission support
          set_file_cache

          save!
        else
          error_message = "Health::HealthFile#set_calculated! with blank file contents. id: #{id}, user_id: #{user_id}, client_id: #{client_id}"
          Rails.logger.error(error_message)
          false
        end
      else
        error_message = "Health::HealthFile#set_calculated! without upload. id: #{id}, user_id: #{user_id}, client_id: #{client_id}"
        Rails.logger.error(error_message)
        false
      end
    rescue ActiveRecord::RecordInvalid => e
      # Validation failed, errors are already on the record
      Rails.logger.error("Health::HealthFile#set_calculated! validation failed: #{e.message}")
      false
    end

    private

    # Process file_cache to restore file on form resubmission (this is to handle the situation where the form has errors, but a file was also included)
    def process_file_cache
      return if file.present? # New file takes precedence
      return if file_cache.blank?
      return if content.present? # Already have content stored

      # Parse cached file data
      begin
        cache_data = JSON.parse(file_cache)
        self.content = Base64.decode64(cache_data['content'])
        self.name = cache_data['name']
        self.content_type = cache_data['content_type']
        self.size = content.bytesize
      rescue JSON::ParserError, KeyError => e
        Rails.logger.error("Failed to process file_cache: #{e.message}")
      end
    end

    # Set file_cache for form resubmission support
    def set_file_cache
      return unless content.present?

      self.file_cache = {
        content: Base64.encode64(content),
        name: name,
        content_type: content_type,
      }.to_json
    end
  end
end
