###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class PublicFile < GrdaWarehouse::File
    include ArelHelper
    acts_as_taggable

    validates_presence_of :name
    validate :file_exists_and_not_too_large

    def file_exists_and_not_too_large
      errors.add :file, 'No uploaded file found' if (content&.size || 0) < 100
      errors.add :file, 'File size should be less than 4 MB' if (content&.size || 0) > 4.megabytes
    end

    def self.known_locations
      {
        'client/hmis_consent' => 'HMIS Consent Form', #  app/controllers/clients/files_controller.rb
        'client/chronic_homelessness_verification' => 'Verification of Chronic Homelessness', # app/controllers/clients/files_controller.rb,
        'client/disability_verification' => 'Verification of Disability', # app/controllers/clients/files_controller.rb,
        'patient/release' => 'Patient Release Form', # app/controllers/health/release_forms_controller.rb
        'patient/directed_release' => 'Patient Directed Release Form', # app/controllers/health/release_forms_controller.rb
        'patient/participation' => 'Participation Form', # app/controllers/health/participation_forms_controller.rb
        'patient/participation_spanish' => 'Participation Form (SPANISH)', # app/controllers/health/participation_forms_controller.rb
        'patient/ssm' => 'SSM Form', # app/controllers/health/self_sufficiency_matrix_forms_controller.rb.rb
        'patient/cha' => 'CHA Form', # app/controllers/health/comprehensive_health_assessments_controller.rb
        'patient/care_plan' => 'Care Plan Form', # app/controllers/health/careplans_controller.rb
        'patient/case_management_note' => 'Case Management Note Form', # app/controllers/health/sdh_case_management_note.rb,
        'client/releases/coc_map' => 'CoC Map (png)', # app/controllers/clients/releases_controller.rb
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
