###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class HrsnScreening < HealthBase
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
      completed_within(.. Date.current)
    end

    scope :incomplete, -> do
      where.not(id: completed.pluck(:id))
    end

    scope :completed_within, ->(range) do
      ssm_ids = joins(:ssm).merge(Health::SelfSufficiencyMatrixForm.completed_within(range)).pluck(:id)
      thrive_ids = joins(:thrive).merge(HealthThriveAssessment::Assessment.completed_within(range)).pluck(:id)
      where(instrument_id: ssm_ids, instrument_type: 'Health::SelfSufficiencyMatrixForm').
        or(where(instrument_id: thrive_ids, instrument_type: 'HealthThriveAssessment::Assessment'))
    end

    scope :allowed_for_engagement, -> do
      ssm_ids = joins(:ssm).merge(Health::SelfSufficiencyMatrixForm.allowed_for_engagement).pluck(:id)
      thrive_ids = joins(:thrive).merge(HealthThriveAssessment::Assessment.allowed_for_engagement).pluck(:id)
      where(instrument_id: ssm_ids, instrument_type: 'Health::SelfSufficiencyMatrixForm').
        or(where(instrument_id: thrive_ids, instrument_type: 'HealthThriveAssessment::Assessment'))
    end
  end
end
