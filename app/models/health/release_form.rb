###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class ReleaseForm < HealthBase
    include ArelHelper

    phi_patient :patient_id

    phi_attr :user_id, Phi::SmallPopulation
    phi_attr :signature_on, Phi::Date
    # phi_attr :file_location, Phi::SmallPopulation
    phi_attr :health_file_id, Phi::OtherIdentifier
    phi_attr :reviewed_by_id, Phi::SmallPopulation
    phi_attr :reviewed_at, Phi::Date
    phi_attr :reviewer, Phi::SmallPopulation

    belongs_to :patient
    belongs_to :user
    belongs_to :reviewed_by, class_name: 'User'

    has_one :health_file, class_name: 'Health::ReleaseFormFile', foreign_key: :parent_id, dependent: :destroy
    include HealthFiles

    validates :signature_on, presence: true
    validate :file_or_location

    scope :recent, -> { order(signature_on: :desc).limit(1) }
    scope :reviewed, -> { where.not(reviewed_by_id: nil) }
    scope :valid, -> do
      parent_ids = Health::ReleaseFormFile.where.not(parent_id: nil).select(:parent_id).to_sql

      where(
        arel_table[:file_location].not_in([:nil, '']).
        or(
          arel_table[:id].in(lit(parent_ids))
        )
      )
    end

    scope :unsigned, -> do
      where(signature_on: nil)
    end
    scope :signed, -> do
      where.not(signature_on: nil)
    end
    scope :active, -> do
      valid.where(arel_table[:signature_on].gteq(2.years.ago))
    end
    scope :expired, -> do
      where(arel_table[:signature_on].lt(2.years.ago))
    end
    scope :expiring_soon, -> do
      where(signature_on: 2.years.ago..23.months.ago)
    end
    scope :recently_signed, -> do
      active.where(arel_table[:signature_on].gteq(1.months.ago))
    end
    scope :during_current_enrollment, -> do
      where(signature_on: patient.current_enrollment_ranges)
    end

    attr_accessor :reviewed_by_supervisor, :file

    def expires_on
      return unless signature_on

      signature_on.to_date + 2.years
    end

    before_save :set_reviewer
    private def set_reviewer
      if reviewed_by
        self.reviewer = reviewed_by.name
        self.reviewed_at = DateTime.current
      end
    end

    def file_or_location
      if health_file.blank? && file_location.blank?
        errors.add :file_location, "Please include either a file location or upload."
      end
      if health_file.present? && health_file.invalid?
        errors.add :health_file, health_file.errors.messages.try(:[], :file)&.uniq&.join('; ')
      end
    end

    def self.encounter_report_details
      {
        source: 'Warehouse',
      }
    end
  end
end