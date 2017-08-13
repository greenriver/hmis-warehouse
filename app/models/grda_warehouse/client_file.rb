module GrdaWarehouse
  class ClientFile < GrdaWarehouse::File
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    validates_presence_of :name
    validates_inclusion_of :visible_in_window, in: [true, false]
    validate :file_exists_and_not_too_large
    mount_uploader :file, FileUploader # Tells rails to use this uploader for this model.
    
    def file_exists_and_not_too_large
      errors.add :file, "No uploaded file found" if (content&.size || 0) < 100
      errors.add :file, "Uploaded file must be less than 2 MB" if (content&.size || 0) > 2.megabytes
    end
  end
end  
