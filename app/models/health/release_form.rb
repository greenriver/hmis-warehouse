module Health
  class ReleaseForm < HealthBase
    mount_uploader :file, FileUploader

    belongs_to :patient
    belongs_to :user

    validates :signature_on, presence: true

    scope :recent, -> { order(signature_on: :desc).limit(1) }

  end
end