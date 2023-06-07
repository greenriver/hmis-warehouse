###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class CaAssessment < HealthBase
    acts_as_paranoid

    belongs_to :instrument, polymorphic: true

    # Internal relations for joins
    belongs_to :cha, -> { where(ca_assessments: { instrument_type: 'Health::ComprehensiveHealthAssessment' }) },
               foreign_key: :instrument_id, class_name: 'Health::ComprehensiveHealthAssessment', optional: true
    belongs_to :ca, -> { where(ca_assessments: { instrument_type: 'HealthComprehensiveAssessment::Assessment' }) },
               foreign_key: :instrument_id, class_name: 'HealthComprehensiveAssessment::Assessment', optional: true

    scope :assessments, -> do
      left_joins(:cha, :ca)
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
      cha_ids = joins(:cha).merge(Health::ComprehensiveHealthAssessment.completed_within(range)).pluck(:instrument_id)
      ca_ids = joins(:ca).merge(HealthComprehensiveAssessment::Assessment.completed_within(range)).pluck(:instrument_id)
      where(instrument_id: cha_ids, instrument_type: 'Health::ComprehensiveHealthAssessment').
        or(where(instrument_id: ca_ids, instrument_type: 'HealthComprehensiveAssessment::Assessment'))
    end

    scope :allowed_for_engagement, -> do
      cha_ids = joins(:cha).merge(Health::ComprehensiveHealthAssessment.allowed_for_engagement).pluck(:instrument_id)
      ca_ids = joins(:ca).merge(HealthComprehensiveAssessment::Assessment.allowed_for_engagement).pluck(:instrument_id)
      where(instrument_id: cha_ids, instrument_type: 'Health::ComprehensiveHealthAssessment').
        or(where(instrument_id: ca_ids, instrument_type: 'HealthComprehensiveAssessment::Assessment'))
    end

    scope :reviewed, -> do
      cha_ids = joins(:cha).merge(Health::ComprehensiveHealthAssessment.reviewed).pluck(:instrument_id)
      ca_ids = joins(:ca).merge(HealthComprehensiveAssessment::Assessment.reviewed).pluck(:instrument_id)
      where(instrument_id: cha_ids, instrument_type: 'Health::ComprehensiveHealthAssessment').
        or(where(instrument_id: ca_ids, instrument_type: 'HealthComprehensiveAssessment::Assessment'))
    end

    scope :reviewed_within, ->(range) do
      cha_ids = joins(:cha).merge(Health::ComprehensiveHealthAssessment.reviewed_within(range)).pluck(:instrument_id)
      ca_ids = joins(:ca).merge(HealthComprehensiveAssessment::Assessment.reviewed_within(range)).pluck(:instrument_id)
      where(instrument_id: cha_ids, instrument_type: 'Health::ComprehensiveHealthAssessment').
        or(where(instrument_id: ca_ids, instrument_type: 'HealthComprehensiveAssessment::Assessment'))
    end
  end
end
