module Health
  class HealthFile < HealthBase
    acts_as_paranoid
    belongs_to :user, required: true
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'

    mount_uploader :file, HealthFileUploader

    validate :file_not_too_large

    def file_not_too_large
      errors.add :file, "File size should be less than 25 MB" if (content&.size || 0) > 25.megabytes
    end

    def title
      self.class.model_name.human
    end
  end
end
