# frozen_string_literal: true

module Hmis::Ce::Match
  class CandidatePoolUnitGroupAssignment < GrdaWarehouseBase
    self.table_name = 'ce_pool_unit_group_assignments'

    # Foreign key constraints in the DB on these two fields are intentionally omitted,
    # to preserve historical records even if the  unit group or candidate pool is deleted.
    belongs_to :unit_group, class_name: 'Hmis::UnitGroup'
    belongs_to :candidate_pool, class_name: 'Hmis::Ce::Match::CandidatePool'

    scope :active, -> { where(ended_at: nil) }
  end
end
