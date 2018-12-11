# ### HIPPA Risk Assessment
# Risk: Indirectly relates to a patient. Binary data may contain PHI
# Control: PHI attributes documented
module Health
  class HealthFile < HealthBase
    acts_as_paranoid

    phi_attr :file, Phi::FreeText
    phi_attr :content, Phi::FreeText
    phi_attr :note, Phi::FreeText

    belongs_to :user, required: true
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'

    mount_uploader :file, HealthFileUploader

    validate :file_not_too_large
    validate :valid_file_type

    def file_not_too_large
      errors.add :file, "File size should be less than #{HealthFileUploader.new.max_size_in_mb} MB" if (content&.size || 0) > HealthFileUploader.new.max_size_in_bytes
    end

    def valid_file_type
      errors.add :file, "File must be a PDF" if content_type != 'application/pdf'
    end

    def title
      self.class.model_name.human
    end

    def set_calculated!(user_id, client_id)
      self.user_id = user_id
      self.client_id = client_id
      self.content = self.file.read
      self.content_type = self.file.content_type
      self.size = self.content&.size
      self.name = self.file.filename
    end
  end
end
