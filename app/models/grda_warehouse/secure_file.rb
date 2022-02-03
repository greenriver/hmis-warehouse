###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class SecureFile < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :recipient, class_name: 'User'
    belongs_to :sender, class_name: 'User'
    validates_presence_of :name
    validate :file_exists_and_not_too_large

    mount_uploader :file, SecureFileUploader # Tells rails to use this uploader for this model.

    scope :visible_by?, ->(user) do
      # If you can see all client files, show everything
      visible_scope = if user.can_view_all_secure_uploads?
        all
      # You can only see files you were sent
      elsif user.can_view_assigned_secure_uploads?
        where(recipient_id: user.id)
      else
        none
      end
      # all secure files expire after 1.month
      visible_scope.unexpired
    end

    scope :expired, -> do
      where(arel_table[:created_at].lt(1.months.ago.to_date))
    end

    scope :unexpired, -> do
      where(arel_table[:created_at].gteq(1.months.ago))
    end

    def self.clean_expired
      expired.update_all(deleted_at: Time.now)
    end

    def file_exists_and_not_too_large
      errors.add :file, 'No uploaded file found' if (content&.size || 0) < 100
      errors.add :file, 'File size should be less than 250 MB' if (content&.size || 0) > 250.megabytes
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
