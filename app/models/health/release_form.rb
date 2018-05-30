module Health
  class ReleaseForm < HealthBase

    belongs_to :patient
    belongs_to :user
    belongs_to :reviewed_by, class_name: 'User'
    belongs_to :health_file, dependent: :destroy

    validates :signature_on, presence: true

    scope :recent, -> { order(signature_on: :desc).limit(1) }

    attr_accessor :reviewed_by_supervisor

  end
end