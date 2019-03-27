module GrdaWarehouse
  class SecureFile < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :recipient, class_name: User.name
    belongs_to :sender, class_name: User.name
    belongs_to :vispdat, class_name: User.name
    validates_presence_of :name
    validate :file_exists_and_not_too_large

    mount_uploader :file, SecureFileUploader # Tells rails to use this uploader for this model.

    scope :visible_by?, -> (user) do
      # If you can see all client files, show everything
      if user.can_view_all_secure_uploads?
        all
      # You can only see files you were sent
      else
        where(recipient_id: user.id)
      end
    end

    def file_exists_and_not_too_large
      errors.add :file, "No uploaded file found" if (content&.size || 0) < 100
      errors.add :file, "File size should be less than 4 MB" if (content&.size || 0) > 4.megabytes
    end

    def as_preview
      return content unless content_type == 'image/jpeg'
      image = MiniMagick::Image.read(content)
      image.auto_level
      image.strip
      image.resize('1920x1080')
      image.to_blob
    end

    def as_thumb
      return nil unless content_type == 'image/jpeg'
      image = MiniMagick::Image.read(content)
      image.auto_level
      image.strip
      image.resize('400x400')
      image.to_blob
    end

  end
end
