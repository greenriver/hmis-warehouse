###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
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

    belongs_to :patient, optional: true
    belongs_to :user, optional: true
    belongs_to :reviewed_by, class_name: 'User', optional: true

    has_one :health_file, class_name: 'Health::ReleaseFormFile', foreign_key: :parent_id, dependent: :destroy
    include HealthFiles

    validates :signature_on, presence: true
    validate :file_or_location

    scope :recent, -> { order(signature_on: :desc).limit(1) }
    scope :reviewed, -> { where.not(reviewed_by_id: nil) }
    scope :valid, -> do
      parent_ids = Health::ReleaseFormFile.where.not(parent_id: nil).pluck(:parent_id)
      where.not(file_location: [nil, '']).
        or(where(id: parent_ids))
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
      where(arel_table[:signature_on].gteq(hpr_t[:enrollment_start_date])).
        joins(patient: :patient_referral)
    end
    scope :during_contributing_enrollments, -> do
      where(arel_table[:signature_on].gteq(hpr_t[:enrollment_start_date])).
        joins(patient: :patient_referrals).
        merge(Health::PatientReferral.contributing)
    end

    scope :allowed_for_engagement, -> do
      joins(patient: :patient_referrals).
        merge(
          Health::PatientReferral.contributing.
            where(
              hpr_t[:enrollment_start_date].lt(Arel.sql("#{arel_table[:signature_on].to_sql} + INTERVAL '1 year'")),
            ),
        )
    end

    attr_accessor :reviewed_by_supervisor, :file

    def expires_on
      return unless signature_on

      signature_on.to_date + 2.years
    end

    before_save :set_reviewer
    private def set_reviewer
      return unless reviewed_by

      self.reviewer = reviewed_by.name
      self.reviewed_at = DateTime.current
    end

    def file_or_location
      errors.add :file_location, 'Please upload a release of information form.' if health_file.blank? && file_location.blank?
      errors.add :health_file, health_file.errors.messages.try(:[], :file)&.uniq&.join('; ') if health_file.present? && health_file.invalid?
    end

    def self.encounter_report_details
      {
        source: 'Warehouse',
      }
    end
  end
end
