###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# ### HIPAA Risk Assessment
# Risk: Indirectly relates to a patient. Binary data may contain PHI
# Control: PHI attributes documented
#
# Uses Active Storage for temporary file caching during form resubmissions.
# Cached files are stored as unattached blobs with signed_ids passed through forms.
# Unattached blobs older than 2 days are purged daily by PurgeUnattachedBlobsJob.
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

    # Virtual attributes to receive uploaded file or cache from form
    attr_accessor :file
    attr_accessor :file_cache

    # --- Form Submission Lifecycle ---
    # 1. process_upload_context (before_validation): Restores from cache OR ingests new upload
    # 2. validate_file_content_and_metadata: Validates content and extracts metadata
    # 3. set_file_cache (side-effect of validation): Updates cache for next render if validation fails
    # 4. set_calculated!: Final orchestration called by controllers to trigger save/persistence

    before_validation :process_upload_context
    validate :validate_file_content_and_metadata

    # Orchestrates the persistence of a health file. Called by controllers (e.g., via HealthFileController concern)
    # after assigning user/client IDs. Returns boolean success.
    def set_calculated!(user_id, client_id)
      self.user_id ||= user_id
      self.client_id ||= client_id

      # Verify we have a file source (upload, cache, or direct content assignment)
      if file.blank? && content.blank? && file_cache.blank?
        Rails.logger.error("Health::HealthFile#set_calculated! called without file data. id: #{id}")
        return false
      end

      # Trigger validations (including before_validation callbacks that populate content)
      return false unless valid?

      # Final check: ensure content was successfully populated
      if content.blank?
        Rails.logger.error("Health::HealthFile#set_calculated! content not populated after validation. id: #{id}")
        errors.add(:file, 'could not be processed')
        return false
      end

      if save
        true
      else
        Rails.logger.error("Health::HealthFile#set_calculated! save failed: #{errors.full_messages.join(', ')}")
        false
      end
    end

    def title
      self.class.model_name.human
    end

    def signature
      nil
    end

    def valid_for_current_enrollment
      return nil unless client.patient&.enrollment_start_date.present?

      signature.present? && signature > client.patient.enrollment_start_date || signature.blank? && created_at > client.patient.enrollment_start_date
    end

    def valid_for_contributing_enrollment
      return nil unless client.patient

      client.patient.contributed_enrollment_ranges.any? do |range|
        range.cover?(signature)
      end
    end

    private

    # Ingests the raw file data from either a new upload (multipart) or a cached signed_id.
    # This ensures `content` and `name` are populated before validations run.
    def process_upload_context
      if file.present?
        # New file takes precedence over cache
        self.content = file.respond_to?(:read) ? file.read : file
        file.rewind if file.respond_to?(:rewind)
        self.name = file.respond_to?(:original_filename) ? file.original_filename : 'uploaded_file.pdf'
      elsif file_cache.present? && content.blank?
        # Restore content from Active Storage if parent form failed validation previously
        process_file_cache
      end
    end

    # Validates that the file is a legitimate PDF (not just by extension).
    # Side-effect: If valid, populates metadata (size, content_type) and updates the temporary cache.
    def validate_file_content_and_metadata
      return if content.blank?
      # Skip re-validation if we already have content and aren't uploading a new file
      return unless new_record? || file.present?

      result = self.class.validate_file_content(
        content,
        file.respond_to?(:content_type) ? file.content_type : nil,
        ['application/pdf'],
        File.extname(name || '.pdf'),
      )

      if result[:valid]
        self.content_type = result[:detected_type]
        self.size = content.bytesize
        # Update the cache so the file persists even if other form fields fail validation
        set_file_cache if file.present?
      else
        errors.add(:file, 'must be a valid PDF')
      end
    end

    # Retrieves file content from Active Storage using a signed_id.
    # Rescues from invalid signatures or missing files gracefully.
    def process_file_cache
      blob = ActiveStorage::Blob.find_signed(file_cache)
      return unless blob

      self.content = blob.download
      self.name = blob.filename.to_s
      self.content_type = blob.content_type
      self.size = blob.byte_size
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveStorage::FileNotFoundError => e
      Rails.logger.error("Failed to process file_cache: #{e.message}")
    end

    # Stores a temporary copy of the file in Active Storage.
    # This allows the signed_id to be passed back to the hidden `file_cache` field in the form.
    def set_file_cache
      return unless content.present?

      # Create an unattached blob directly. These are purged daily by PurgeUnattachedBlobsJob.
      # Note: We don't use has_one_attached for the final record to avoid redundant storage.
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(content),
        filename: name,
        content_type: content_type,
      )
      self.file_cache = blob.signed_id
    end
  end
end
