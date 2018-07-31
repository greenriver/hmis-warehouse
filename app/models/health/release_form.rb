module Health
  class ReleaseForm < HealthBase

    belongs_to :patient
    belongs_to :user
    belongs_to :reviewed_by, class_name: 'User'
    # belongs_to :health_file, dependent: :destroy

    has_one :health_file, class_name: 'Health::ReleaseFormFile', foreign_key: :parent_id, dependent: :destroy
    accepts_nested_attributes_for :health_file, allow_destroy: true, reject_if: proc {|att| att['file'].blank? && att['file_cache'].blank?}
    validates_associated :health_file

    validates :signature_on, presence: true
    validate :file_or_location

    scope :recent, -> { order(signature_on: :desc).limit(1) }
    scope :reviewed, -> { where.not(reviewed_by_id: nil) }
    scope :valid, -> do
      where(arel_table[:file_location].not_in([:nil, '']).or(arel_table[:id].in(Health::ReleaseFormFile.select(:parent_id))))
    end

    attr_accessor :reviewed_by_supervisor, :file

    before_save :set_reviewer
    private def set_reviewer
      if reviewed_by
        self.reviewer = reviewed_by.name
        self.reviewed_at = DateTime.current
      end
    end

    def can_display_health_file?
      health_file.present? && health_file.size
    end

    def downloadable?
      health_file.present? && health_file.persisted?
    end

    def file_or_location
      if health_file.blank? && file_location.blank?
        errors.add :file_location, "Please include either a file location or upload."
      end
      if health_file.present? && health_file.invalid?
        errors.add :health_file, health_file.errors.messages.try(:[], :file)&.uniq&.join('; ')
      end
    end
  end
end