module Health
  class ParticipationForm < HealthBase

    belongs_to :case_manager, class_name: 'User'
    belongs_to :reviewed_by, class_name: 'User'

    validates :location, presence: true

    scope :recent, -> { order(signature_on: :desc).limit(1) }

  end
end