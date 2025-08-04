# frozen_string_literal: true

# an eligible, prioritized client for a given candidate pool
module Hmis::Ce::Match
  class Candidate < GrdaWarehouseBase
    self.table_name = 'ce_match_candidates'
    belongs_to :candidate_pool, class_name: 'Hmis::Ce::Match::CandidatePool'
    belongs_to :client_proxy, class_name: 'Hmis::Ce::ClientProxy'

    # todo @martha - is causing n+1?
    scope :prioritized, -> {
      # Order by priority_scores arrays:
      # Compare element by element (priority_scores[0], then priority_scores[1], etc.)
      # Higher scores come first, nulls come last, shorter arrays are treated as having trailing nulls
      order(
        arel_table[:priority_scores].desc.nulls_last,
        arel_table[:id].asc,
      )
    }

    # Which candidates (clients) are eligible for an opportunity
    scope :for_opportunity, ->(opportunity) do
      return Hmis::Ce::Match::Candidate.none unless opportunity.candidate_pool

      opportunity.candidate_pool.candidates
    end
  end
end
