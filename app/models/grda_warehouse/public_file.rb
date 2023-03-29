###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class PublicFile < GrdaWarehouse::File
    include ArelHelper
    mount_uploader :file, FileUploader
    acts_as_taggable

    validates_presence_of :name
    validate :file_exists_and_not_too_large

    def file_exists_and_not_too_large
      errors.add :file, 'No uploaded file found' if (content&.size || 0) < 100
      errors.add :file, 'File size should be less than 4 MB' if (content&.size || 0) > 4.megabytes
    end

    def self.known_locations
      {
        'client/hmis_consent' => _('HMIS Consent Form'), #  app/controllers/clients/files_controller.rb
        'client/chronic_homelessness_verification' => _('Verification of Chronic Homelessness'), # app/controllers/clients/files_controller.rb,
        'client/disability_verification' => _('Verification of Disability'), # app/controllers/clients/files_controller.rb,
        'patient/release' => _('Patient Signature Form'), # app/controllers/health/release_forms_controller.rb
        'patient/directed_release' => _('Verbal (Directed) Signature Form'), # app/controllers/health/release_forms_controller.rb
        'patient/release_spanish' => _('Spanish Patient Signature Form'), # app/controllers/health/release_forms_controller.rb
        'patient/directed_release_spanish' => _('Spanish Verbal (Directed) Signature Form'), # app/controllers/health/release_forms_controller.rb
        'patient/participation' => _('Participation Form [Unused]'), # app/controllers/health/participation_forms_controller.rb
        'patient/participation_spanish' => _('Participation Form (SPANISH) [Unused]'), # app/controllers/health/participation_forms_controller.rb
        'patient/directed_participation' => _('Patient Directed Participation Form [Unused]'), # app/controllers/health/participation_forms_controller.rb
        'patient/ssm' => _('SSM Form'), # app/controllers/health/self_sufficiency_matrix_forms_controller.rb.rb
        'patient/cha' => _('CHA Form'), # app/controllers/health/comprehensive_health_assessments_controller.rb
        'patient/care_plan' => _('Care Plan Form'), # app/controllers/health/careplans_controller.rb
        'patient/case_management_note' => _('Case Management Note Form'), # app/controllers/health/sdh_case_management_note.rb,
        'client/releases/coc_map' => _('CoC Map (png)'), # app/controllers/clients/releases_controller.rb
      }
    end

    def self.known_hmis_locations
      known_locations.select { |k, _| k.starts_with?('client/') }
    end

    def self.known_health_locations
      known_locations.select { |k, _| k.starts_with?('patient/') }
    end

    def self.url_for_location location
      if (id = order(id: :desc).where(name: location).pluck(:id)&.first) # rubocop:disable Style/GuardClause:
        Rails.application.routes.url_helpers.public_file_path(id: id)
      end
    end
  end
end
