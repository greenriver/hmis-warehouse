module Health
  class ParticipationForm < HealthBase

    belongs_to :case_manager, class_name: 'User'
    belongs_to :reviewed_by, class_name: 'User'
    belongs_to :health_file, dependent: :destroy

    validates :signature_on, presence: true
    validate :file_or_location

    scope :recent, -> { order(signature_on: :desc).limit(1) }
    scope :reviewed, -> { where.not(reviewed_by_id: nil) }
    scope :valid, -> do
      where(arel_table[:location].not_in([:nil, '']).or(arel_table[:health_file_id].not_eq(nil)))
    end

    attr_accessor :reviewed_by_supervisor, :file

    before_save :set_reviewer
    private def set_reviewer
      if reviewed_by
        self.reviewer = reviewed_by.name
        self.reviewed_at = DateTime.current
      end
    end

    def file_or_location
      if file.blank? && location.blank?
        errors.add :location, "Please include either a file location or upload."
      end
      if file.present? && file.invalid?
        errors.add :file, file.errors.messages.try(:[], :file)&.uniq&.join('; ')
      end
    end
  end
end