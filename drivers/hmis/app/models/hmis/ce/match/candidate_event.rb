# frozen_string_literal: true

module Hmis::Ce::Match
  class CandidateEvent < GrdaWarehouseBase
    self.table_name = 'ce_match_candidate_events'

    belongs_to :pool, class_name: 'Hmis::Ce::Match::CandidatePool', foreign_key: :candidate_pool_id
    belongs_to :client_proxy, class_name: 'Hmis::Ce::ClientProxy'
  end
end
