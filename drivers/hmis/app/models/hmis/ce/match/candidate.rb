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
      search_term = search_term.strip

      # If it's a possible PK, check if it's a Candidate primary key
      if possibly_pk?(search_term)
        matching_candidates = where(id: search_term.to_i)
        return matching_candidates if matching_candidates.exists?
      end

      # Search by client through client_proxy -> destination_client -> hmis_source_clients
      candidate_ids = joins(client_proxy: { destination_client: :hmis_source_clients }).
        merge(Hmis::Hud::Client.matching_search_term(search_term)).
        pluck(:id).uniq

      where(id: candidate_ids)
    end
  end
end
