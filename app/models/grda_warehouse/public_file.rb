###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class PublicFile < GrdaWarehouse::File
    include ArelHelper
    has_one_attached :public_file, dependent: false
    acts_as_taggable

    ALLOWED_CONTENT_TYPES = [
      'image/jpeg',
      'image/png',
      'image/gif',
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/csv',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/octet-stream',
    ].freeze

    validates_presence_of :name
    validate :file_exists_and_not_too_large
    validate :content_type_allowed, on: :create

    def file_data
      return public_file.download if public_file.attached?

      content
    end

    def file_exists_and_not_too_large
      size = if public_file.attached?
        public_file.byte_size
      else
        content&.size
      end
      errors.add :file, 'No uploaded file found' if (size || 0) < 100
      errors.add :file, 'File size should be less than 4 MB' if (size || 0) > 4.megabytes
    end

    # A client-supplied MIME type can be spoofed. ActiveStorage derives the blob's
    # content type from the actual bytes, so validate and store that instead.
    def detected_content_type
      return content_type unless public_file.attached?

      public_file.blob&.content_type || content_type
    end

    def content_type_allowed
      return unless public_file.attached?

      detected = detected_content_type
      return if ALLOWED_CONTENT_TYPES.include?(detected)

      errors.add(:file, "You are not allowed to upload #{detected} files")
    end

    def self.known_locations
      {
        'client/hmis_consent' => Translation.translate('HMIS Consent Form'), #  app/controllers/clients/files_controller.rb
        'client/chronic_homelessness_verification' => Translation.translate('Verification of Chronic Homelessness'), # app/controllers/clients/files_controller.rb,
        'client/disability_verification' => Translation.translate('Verification of Disability'), # app/controllers/clients/files_controller.rb,
        'client/releases/coc_map' => Translation.translate('CoC Map (png)'), # app/controllers/clients/releases_controller.rb
      }
    end

    def self.known_hmis_locations
      known_locations.select { |k, _| k.starts_with?('client/') }
    end

    def self.known_health_locations
      known_locations.select { |k, _| k.starts_with?('patient/') }
    end

    def self.url_for_location location
      if (id = order(id: :desc).where(name: location).pluck(:id)&.first)
        Rails.application.routes.url_helpers.public_file_path(id: id)
      end
    end
  end
end
