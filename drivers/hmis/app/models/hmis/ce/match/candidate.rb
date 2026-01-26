# frozen_string_literal: true

# an eligible, prioritized client for a given candidate pool
module Hmis::Ce::Match
  class Candidate < GrdaWarehouseBase
    # Bulk-managed, does not log to paper_trail
    self.table_name = 'ce_match_candidates'
    belongs_to :candidate_pool, class_name: 'Hmis::Ce::Match::CandidatePool'
    belongs_to :client_proxy, class_name: 'Hmis::Ce::ClientProxy'

    scope :prioritized, -> {
      # Order by priority_scores arrays.
      # Postgres array comparison compares element by element (priority_scores[0], then priority_scores[1], etc.)
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

    # Free-text search for Candidate
    scope :matching_search_term, ->(search_term) do
      joins(:client_proxy).
        merge(Hmis::Ce::ClientProxy.matching_search_term(search_term))
    end
  end
end
