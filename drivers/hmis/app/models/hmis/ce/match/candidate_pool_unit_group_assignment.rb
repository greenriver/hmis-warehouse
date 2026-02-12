# frozen_string_literal: true

module Hmis::Ce::Match
  class CandidatePoolUnitGroupAssignment < GrdaWarehouseBase
    self.table_name = 'ce_pool_unit_group_assignments'

    belongs_to :unit_group, class_name: 'Hmis::UnitGroup'
    belongs_to :candidate_pool, class_name: 'Hmis::Ce::Match::CandidatePool'

    validate :ended_at_after_started_at

    scope :active, -> { where(ended_at: nil) }

    private

    def ended_at_after_started_at
      return if ended_at.nil? || started_at.nil?

      errors.add(:ended_at, 'must be after started_at') if ended_at <= started_at
    end
  end
end
