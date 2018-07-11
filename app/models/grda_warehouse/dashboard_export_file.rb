module GrdaWarehouse
  class DashboardExportFile < GrdaWarehouse::File
    mount_uploader :file, FileUploader # Tells rails to use this uploader for this model.
    
  end
end
