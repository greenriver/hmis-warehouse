###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class PctpCareplan < HealthBase
    self.table_name = :any_careplans # pctp_careplans is the name of the HealthPctp::Careplan table
    acts_as_paranoid

    # Health::Careplan.find_in_batches do |batch|
    #   v1s = []
    #   batch.each do |cp|
    #     v1s << Health::PctpCareplan.new(patient_id: cp.patient_id, instrument_type: 'Health::Careplan', instrument_id: cp.id)
    #   end
    #   Health::PctpCareplan.import(v1s)
    # end
    #
    # HealthPctp::Careplan.find_in_batches do |batch|
    #   v2s = []
    #   batch.each do |cp|
    #     v2s << Health::PctpCareplan.new(patient_id: cp.patient_id, instrument_type: 'HealthPctp::Careplan', instrument_id: cp.id)
    #   end
    #   Health::PctpCareplan.import(v2s)
    # end

    belongs_to :instrument, polymorphic: true

    # Internal relations for joins
    belongs_to :v1, -> { where(any_careplans: { instrument_type: 'Health::Careplan' }) },
               foreign_key: :instrument_id, class_name: 'Health::Careplan', optional: true
    belongs_to :v2, -> { where(any_careplans: { instrument_type: 'HealthPctp::Careplan' }) },
               foreign_key: :instrument_id, class_name: 'HealthPctp::Careplan', optional: true

    scope :careplans, -> do
      left_joins(:v1, :v2)
    end

    scope :recent, -> do
      sorted.limit(1)
    end

    scope :sorted, -> do
      order(created_at: :desc)
    end

    scope :editable, -> do
      v1_ids = joins(:v1).merge(Health::Careplan.editable).pluck(:instrument_id)
      v2_ids = joins(:v2).merge(HealthPctp::Careplan.editable).pluck(:instrument_id)
      where(instrument_id: v1_ids, instrument_type: 'Health::Careplan').
        or(where(instrument_id: v2_ids, instrument_type: 'HealthPctp::Careplan'))
    end

    scope :completed, -> do
      completed_within(.. Date.current)
    end

    scope :incomplete, -> do
      where.not(id: completed.pluck(:id))
    end

    scope :rn_approved, -> do
      reviewed_within(.. Date.current)
    end

    scope :completed_within, ->(range) do
      v1_ids = joins(:v1).merge(Health::Careplan.completed_within(range)).pluck(:instrument_id)
      v2_ids = joins(:v2).merge(HealthPctp::Careplan.completed_within(range)).pluck(:instrument_id)
      where(instrument_id: v1_ids, instrument_type: 'Health::Careplan').
        or(where(instrument_id: v2_ids, instrument_type: 'HealthPctp::Careplan'))
    end

    scope :allowed_for_engagement, -> do
      v1_ids = joins(:v1).merge(Health::Careplan.allowed_for_engagement).pluck(:instrument_id)
      v2_ids = joins(:v2).merge(HealthPctp::Careplan.allowed_for_engagement).pluck(:instrument_id)
      where(instrument_id: v1_ids, instrument_type: 'Health::Careplan').
        or(where(instrument_id: v2_ids, instrument_type: 'HealthPctp::Careplan'))
    end

    scope :reviewed_within, ->(range) do
      v1_ids = joins(:v1).merge(Health::Careplan.reviewed_within(range)).pluck(:instrument_id)
      v2_ids = joins(:v2).merge(HealthPctp::Careplan.reviewed_within(range)).pluck(:instrument_id)
      where(instrument_id: v1_ids, instrument_type: 'Health::Careplan').
        or(where(instrument_id: v2_ids, instrument_type: 'HealthPctp::Careplan'))
    end
  end
end
