module GrdaWarehouse
  class PublicFile < GrdaWarehouse::File
    include ArelHelper
    acts_as_taggable
  
    validates_presence_of :name
    validate :file_exists_and_not_too_large

    def file_exists_and_not_too_large
      errors.add :file, "No uploaded file found" if (content&.size || 0) < 100
      errors.add :file, "File size should be less than 2 MB" if (content&.size || 0) > 2.megabytes
    end

    def self.known_locations
      {
        'client/hmis_consent' => 'HMIS Consent Form', # app/controllers/window/clients/vispdats_controller.rb & app/controllers/window/clients/files_controller.rb 
        'patient/release' => 'Patient Release Form', # app/controllers/window/health/release_forms_controller.rb
        'patient/participation' => 'Participation Form', # app/controllers/window/health/participation_forms_controller.rb
      }
    end

    def self.url_for_location location
      if id = order(id: :desc).where(name: location).pluck(:id)&.first
        Rails.application.routes.url_helpers.public_file_path(id: id)
      end
    end

  end
end  
