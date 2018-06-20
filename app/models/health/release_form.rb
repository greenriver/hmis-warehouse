module Health
  class ReleaseForm < HealthBase

    belongs_to :patient
    belongs_to :user
    belongs_to :reviewed_by, class_name: 'User'
    belongs_to :health_file, dependent: :destroy

    validates :signature_on, presence: true

    scope :recent, -> { order(signature_on: :desc).limit(1) }
    scope :reviewed, -> { where.not(reviewed_by_id: nil) }

    attr_accessor :reviewed_by_supervisor

    before_save :set_reviewer

    private

    def set_reviewer
      if reviewed_by
        self.reviewer = reviewed_by.name
        self.reviewed_at = DateTime.current
      end
    end

  end
end