###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class PublicFile < GrdaWarehouse::File
    include ArelHelper
    mount_uploader :file, FileUploader
    has_one_attached :public_file, dependent: false
    acts_as_taggable

    # CarrierWave's FileUploader#content_type_whitelist used to reject these on
    # upload; new uploads go straight to ActiveStorage and bypass CarrierWave
    # entirely, so validate the same whitelist here.
    ALLOWED_CONTENT_TYPES = (FileUploader::WHITELIST + ['application/octet-stream']).freeze

    validates_presence_of :name
    validate :file_exists_and_not_too_large
    validate :content_type_allowed, on: :create

    def file_data
      return public_file.download if public_file.attached?

      content
    end

    scope :unprocessed_s3_migration, -> do
      migrated = ActiveStorage::Attachment.where(record_type: 'GrdaWarehouse::File', name: 'public_file').pluck(:record_id)
      all = pluck(:id)
      unmigrated = all - migrated
      return none if unmigrated.blank?

      where(id: unmigrated)
    end

    def copy_to_s3!
      return unless content.present?
      return if public_file.attached?

      Tempfile.create(binmode: true) do |tmp_file|
        tmp_file.write(content)
        tmp_file.rewind
        self.content = nil
        public_file.attach(io: tmp_file, content_type: content_type, filename: name.presence || 'file', identify: false)
        save!(validate: false)
      end
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

    def content_type_allowed
      return unless public_file.attached?
      return if ALLOWED_CONTENT_TYPES.include?(content_type)

      errors.add(:file, "You are not allowed to upload #{content_type} files")
    end

    def self.known_locations
      {
        'client/hmis_consent' => Translation.translate('HMIS Consent Form'), #  app/controllers/clients/files_controller.rb
        'client/chronic_homelessness_verification' => Translation.translate('Verification of Chronic Homelessness'), # app/controllers/clients/files_controller.rb,
        'client/disability_verification' => Translation.translate('Verification of Disability'), # app/controllers/clients/files_controller.rb,
        'patient/release' => Translation.translate('Patient Signature Form'), # app/controllers/health/release_forms_controller.rb
        'patient/directed_release' => Translation.translate('Verbal (Directed) Signature Form'), # app/controllers/health/release_forms_controller.rb
        'patient/release_spanish' => Translation.translate('Spanish Patient Signature Form'), # app/controllers/health/release_forms_controller.rb
        'patient/directed_release_spanish' => Translation.translate('Spanish Verbal (Directed) Signature Form'), # app/controllers/health/release_forms_controller.rb
        'patient/participation' => Translation.translate('Participation Form [Unused]'), # app/controllers/health/participation_forms_controller.rb
        'patient/participation_spanish' => Translation.translate('Participation Form (SPANISH) [Unused]'), # app/controllers/health/participation_forms_controller.rb
        'patient/directed_participation' => Translation.translate('Patient Directed Participation Form [Unused]'), # app/controllers/health/participation_forms_controller.rb
        'patient/ssm' => Translation.translate('SSM Form'), # app/controllers/health/self_sufficiency_matrix_forms_controller.rb.rb
        'patient/cha' => Translation.translate('CHA Form'), # app/controllers/health/comprehensive_health_assessments_controller.rb
        'patient/care_plan' => Translation.translate('Care Plan Form'), # app/controllers/health/careplans_controller.rb
        'patient/case_management_note' => Translation.translate('Case Management Note Form'), # app/controllers/health/sdh_case_management_note.rb,
        'client/releases/coc_map' => Translation.translate('CoC Map (png)'), # app/controllers/clients/releases_controller.rb
        'patient/careplan_logo' => Translation.translate('Careplan Logo'), # drivers/health_pctp/app/controllers/health_pctp/careplans_controller.rb
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
