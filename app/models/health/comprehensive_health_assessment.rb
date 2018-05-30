module Health
  class ComprehensiveHealthAssessment < HealthBase

    belongs_to :patient
    belongs_to :user
    belongs_to :reviewed_by, class_name: 'User'
    belongs_to :health_file, dependent: :destroy

    enum status: [:not_started, :in_progress, :complete]

    scope :recent, -> { order(created_at: :desc).limit(1) }

    attr_accessor :reviewed_by_supervisor, :completed

  end
end