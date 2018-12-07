# ### HIPPA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class ParticipationForm < HealthBase
    include ArelHelper
    phi_patient :patient_id

    phi_attr :signature_on, Phi::Date
    phi_attr :case_manager_id, Phi::SmallPopulation
    phi_attr :reviewed_by_id, Phi::SmallPopulation
    phi_attr :location, Phi::SmallPopulation
    phi_attr :health_file_id, Phi::SmallPopulation
    phi_attr :reviewed_at, Phi::Date
    phi_attr :reviewer, Phi::SmallPopulation

    belongs_to :case_manager, class_name: 'User'
    belongs_to :reviewed_by, class_name: 'User'

    has_one :health_file, class_name: 'Health::ParticipationFormFile', foreign_key: :parent_id, dependent: :destroy
    include HealthFiles

    validates :signature_on, presence: true
    validate :file_or_location

    scope :recent, -> { order(signature_on: :desc).limit(1) }
    scope :reviewed, -> { where.not(reviewed_by_id: nil) }
    scope :valid, -> do
      parent_ids = Health::ParticipationFormFile.where.not(parent_id: nil).select(:parent_id).to_sql

      where(
        arel_table[:location].not_in([:nil, '']).
        or(
          arel_table[:id].in(lit(parent_ids))
        )
      )
    end

    scope :signed, -> do
      where.not(signature_on: nil)
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
      if health_file.blank? && location.blank?
        errors.add :location, "Please include either a file location or upload."
      end
      if health_file.present? && health_file.invalid?
        errors.add :health_file, health_file.errors.messages.try(:[], :file)&.uniq&.join('; ')
      end
    end
  end
end