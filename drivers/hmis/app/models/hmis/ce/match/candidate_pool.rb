# frozen_string_literal: true

# Describes the eligibility requirements and prioritization for a client.

module Hmis::Ce::Match
  class CandidatePool < GrdaWarehouseBase
    self.table_name = 'ce_match_candidate_pools'
    has_many :candidates, class_name: 'Hmis::Ce::Match::Candidate', foreign_key: :candidate_pool_id, dependent: :destroy
    has_many :opportunities, class_name: 'Hmis::Ce::Opportunity', dependent: :restrict_with_exception
  end
end
