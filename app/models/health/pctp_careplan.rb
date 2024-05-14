###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class PctpCareplan < HealthBase
    include ArelHelper

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
      one_for_column([:created_at, :instrument_id], source_arel_table: arel_table, group_on: :patient_id)
    end

    scope :sorted, -> do
      order(created_at: :desc, instrument_id: :desc)
    end

    scope :editable, -> do
      v1_ids = joins(:v1).merge(Health::Careplan.editable).select(:instrument_id)
      v2_ids = joins(:v2).merge(HealthPctp::Careplan.editable).select(:instrument_id)
      where(instrument_id: v1_ids, instrument_type: 'Health::Careplan').
        or(where(instrument_id: v2_ids, instrument_type: 'HealthPctp::Careplan'))
    end

    scope :completed, -> do
      completed_within(.. Date.current.end_of_day)
    end

    scope :sent, -> do
      sent_within(.. Date.current)
    end

    scope :incomplete, -> do
      where.not(id: completed.pluck(:id))
    end

    scope :rn_approved, -> do
      reviewed_within(.. Date.current.end_of_day)
    end

    scope :completed_within, ->(range) do
      v1_ids = joins(:v1).merge(Health::Careplan.completed_within(range)).select(:instrument_id)
      v2_ids = joins(:v2).merge(HealthPctp::Careplan.completed_within(range)).select(:instrument_id)
      where(instrument_id: v1_ids, instrument_type: 'Health::Careplan').
        or(where(instrument_id: v2_ids, instrument_type: 'HealthPctp::Careplan'))
    end

    scope :allowed_for_engagement, -> do
      v1_ids = joins(:v1).merge(Health::Careplan.allowed_for_engagement).select(:instrument_id)
      v2_ids = joins(:v2).merge(HealthPctp::Careplan.allowed_for_engagement).select(:instrument_id)
      where(instrument_id: v1_ids, instrument_type: 'Health::Careplan').
        or(where(instrument_id: v2_ids, instrument_type: 'HealthPctp::Careplan'))
    end

    scope :reviewed_within, ->(range) do
      v1_ids = joins(:v1).merge(Health::Careplan.reviewed_within(range)).select(:instrument_id)
      v2_ids = joins(:v2).merge(HealthPctp::Careplan.reviewed_within(range).signature_present).select(:instrument_id)
      where(instrument_id: v1_ids, instrument_type: 'Health::Careplan').
        or(where(instrument_id: v2_ids, instrument_type: 'HealthPctp::Careplan'))
    end

    scope :sent_within, ->(range) do
      v1_ids = joins(:v1).merge(Health::Careplan.sent_within(range)).select(:instrument_id)
      v2_ids = joins(:v2).merge(HealthPctp::Careplan.sent_within(range)).select(:instrument_id)
      where(instrument_id: v1_ids, instrument_type: 'Health::Careplan').
        or(where(instrument_id: v2_ids, instrument_type: 'HealthPctp::Careplan'))
    end

    # A Careplan expires 12 months after it is fully reviewed and sent to the PCP
    # @return [Date] Careplan expiration date
    def expires_on
      return nil unless instrument.careplan_sent_on.present?

      instrument.careplan_sent_on + 12.months
    end

    # A Careplan is active if it was fully reviewed and the expiration date is in the future
    # @return [Boolean] True if the careplan is active
    def active?
      return false unless instrument.careplan_sent_on.present?
      return false if expired?

      expires_on >= Date.current
    end

    # A Careplan is expiring if it is active and will expire in the next month
    # # @return [Boolean] True if the careplan is expiring
    def expiring?
      return false unless expires_on.present?

      active? && expires_on - 1.month < Date.current
    end

    # A Careplan has expired if it is for the current program, and the expiration date is in the past
    # # @return [Boolean] True if the careplan is expired
    def expired?
      return false unless expires_on.present?
      return false unless instrument.cp2?

      expires_on < Date.current
    end
  end
end
