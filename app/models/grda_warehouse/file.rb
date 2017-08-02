module GrdaWarehouse
  class File < GrdaWarehouseBase    
    acts_as_paranoid
    belongs_to :user, required: true
    validates :file, presence: true
    
    mount_uploader :file, FileUploader # Tells rails to use this uploader for this model.
    
    # protected
    # 
    # def sanitize_filename(filename)
    #   # Get only the filename, not the whole path (for IE)
    #   # Thanks to this article I just found for the tip: http://mattberther.com/2007/10/19/uploading-files-to-a-database-using-rails
    #   return File.basename(filename)
    # end
    # 
    # NUM_BYTES_IN_MEGABYTE = 1048576
    # def file_size_under_one_mb
    #   if (@file.size.to_f / NUM_BYTES_IN_MEGABYTE) > 1
    #     errors.add(:file, 'File size cannot be over one megabyte.')
    #   end
    # end
  end
end  
