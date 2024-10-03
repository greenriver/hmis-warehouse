###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class HrsnScreening < HealthBase
    include ArelHelper

    acts_as_paranoid

    belongs_to :instrument, polymorphic: true

    # Internal relations for joins
    belongs_to :ssm, -> { where(hrsn_screenings: { instrument_type: 'Health::SelfSufficiencyMatrixForm' }) },
               foreign_key: :instrument_id, class_name: 'Health::SelfSufficiencyMatrixForm', optional: true
    belongs_to :thrive, -> { where(hrsn_screenings: { instrument_type: 'HealthThriveAssessment::Assessment' }) },
               foreign_key: :instrument_id, class_name: 'HealthThriveAssessment::Assessment', optional: true

    scope :screenings, -> do
      left_joins(:ssm, :thrive)
    end

    scope :recent, -> do
      order(created_at: :desc).limit(1)
    end

    scope :completed, -> do
      completed_within(.. Date.current.end_of_day)
    end

    scope :incomplete, -> do
      where.not(id: completed.pluck(:id))
    end

    scope :newest_first, -> do
      h_screening_t = arel_table
      h_thrive_t = HealthThriveAssessment::Assessment.arel_table
      left_outer_joins(:ssm, :thrive).
        order(cl(h_thrive_t[:completed_on], h_ssm_t[:completed_at], h_screening_t[:created_at]).desc)
    end

    scope :completed_within, ->(range) do
      ssm_ids = joins(:ssm).merge(Health::SelfSufficiencyMatrixForm.completed_within(range)).pluck(:instrument_id)
      thrive_ids = joins(:thrive).merge(HealthThriveAssessment::Assessment.completed_within(range)).pluck(:instrument_id)
      where(instrument_id: ssm_ids, instrument_type: 'Health::SelfSufficiencyMatrixForm').
        or(where(instrument_id: thrive_ids, instrument_type: 'HealthThriveAssessment::Assessment'))
    end

    scope :allowed_for_engagement, -> do
      ssm_ids = joins(:ssm).merge(Health::SelfSufficiencyMatrixForm.allowed_for_engagement).pluck(:instrument_id)
      thrive_ids = joins(:thrive).merge(HealthThriveAssessment::Assessment.allowed_for_engagement).pluck(:instrument_id)
      where(instrument_id: ssm_ids, instrument_type: 'Health::SelfSufficiencyMatrixForm').
        or(where(instrument_id: thrive_ids, instrument_type: 'HealthThriveAssessment::Assessment'))
    end

    def expires_on
      return nil unless instrument.completed_at.present?

      instrument.completed_at + 12.months
    end

    def active?
      instrument.active?
    end

    def expiring?
      return false unless expires_on.present?

      active? && expires_on - 1.month < Date.current
    end

    def expired?
      return false unless expires_on.present?

      expires_on < Date.current
    end
  end
end
