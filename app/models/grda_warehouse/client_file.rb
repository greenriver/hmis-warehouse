module GrdaWarehouse
  class ClientFile < GrdaWarehouse::File
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    # mount_uploader :file, FileUploader # Tells rails to use this uploader for this model.
  end
end  
