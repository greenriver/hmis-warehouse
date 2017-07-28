module GrdaWarehouse
  class File < GrdaWarehouseBase    
    acts_as_paranoid
    belongs_to :user, required: true
    validates :file, presence: true
    
    mount_uploader :file, FileUploader # Tells rails to use this uploader for this model.
  end
end  
