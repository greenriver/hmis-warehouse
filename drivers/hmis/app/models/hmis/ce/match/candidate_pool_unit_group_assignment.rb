# frozen_string_literal: true

module Hmis::Ce::Match
  class CandidatePoolUnitGroupAssignment < GrdaWarehouseBase
    self.table_name = 'ce_pool_unit_group_assignments'

    # Foreign key constraints in the DB on these two fields are intentionally omitted,
    # to preserve historical records even if the  unit group or candidate pool is deleted.
    belongs_to :unit_group, class_name: 'Hmis::UnitGroup'
    belongs_to :candidate_pool, class_name: 'Hmis::Ce::Match::CandidatePool'

    validate :ended_at_after_started_at
    validate :one_active_per_unit_group

    scope :active, -> { where(ended_at: nil) }

    private

    def ended_at_after_started_at
      return if ended_at.nil? || started_at.nil?

      errors.add(:ended_at, 'must be after started at') if ended_at <= started_at
    end

    def one_active_per_unit_group
      return if ended_at.present?
      return unless Hmis::Ce::Match::CandidatePoolUnitGroupAssignment.active.exists?(unit_group_id: unit_group_id)

      errors.add(:base, 'Only one active assignment per unit group is allowed')
    end
  end
end
