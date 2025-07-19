# frozen_string_literal: true

module Hmis::Ce::Match
  class CandidateEvent < GrdaWarehouseBase
    self.table_name = 'ce_match_candidate_events'

    belongs_to :candidate_pool, class_name: 'Hmis::Ce::Match::CandidatePool', foreign_key: :candidate_pool_id
    belongs_to :client_proxy, class_name: 'Hmis::Ce::ClientProxy', foreign_key: :client_proxy_id
  end
end
