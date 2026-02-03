# frozen_string_literal: true

module Hmis::Ce::Match
  class CandidateEvent < GrdaWarehouseBase
    # Bulk-managed, does not log to paper_trail
    self.table_name = 'ce_match_candidate_events'

    belongs_to :unit_group, class_name: 'Hmis::UnitGroup', foreign_key: :unit_group_id, optional: false # Unit group is nullable in the DB for existing events
    belongs_to :candidate_pool, class_name: 'Hmis::Ce::Match::CandidatePool', foreign_key: :candidate_pool_id, optional: true
    belongs_to :client_proxy, class_name: 'Hmis::Ce::ClientProxy', foreign_key: :client_proxy_id

    validates :unit_group_id, presence: true
  end
end
