# frozen_string_literal: true

# an eligible, prioritized client for a given candidate pool
module Hmis::Ce::Match
  class Candidate < GrdaWarehouseBase
    self.table_name = 'ce_match_candidates'
    belongs_to :candidate_pool, class_name: 'Hmis::Ce::Match::CandidatePool'
    belongs_to :client_proxy, class_name: 'Hmis::Ce::ClientProxy'

    has_many :opportunities, through: :candidate_pool, class_name: 'Hmis::Ce::Opportunity'
    has_many :units, through: :opportunities, class_name: 'Hmis::Unit'
    has_many :unit_groups, through: :units, class_name: 'Hmis::UnitGroup'

    # order by descending priority, NULL values last. Use id as a tie-breaker
    scope :prioritized, -> {
      order(
        arel_table[:priority_score].desc.nulls_last,
        arel_table[:id].asc,
      )
    }

    # Which candidates (clients) are eligible for an opportunity
    scope :for_opportunity, ->(opportunity) do
      return Hmis::Ce::Opportunity.none unless opportunity.candidate_pool

      opportunity.candidate_pool.candidates
    end

    # FIXME make this a multi key has_many association
    # def ce_match_candidate_events
    #   Hmis::Ce::Match::CandidateEvent.where(candidate_pool_id: candidate_pool_id, client_proxy_id: client_proxy_id)
    # end

    # used to back CeCandidateConsolidated type
    def self.all_candidates_by_distinct_unit_group
      # Hmis::Ce::Match::Candidate.
      #   joins(candidate_pool: { opportunities: { unit: :unit_group } }).
      #   select('ce_match_candidates.*, hmis_unit_groups.id AS unit_group_id').
      #   distinct

      latest_event_subquery = Hmis::Ce::Match::CandidateEvent.
        select('DISTINCT ON (candidate_pool_id, client_proxy_id) id, candidate_pool_id, client_proxy_id').
        order('candidate_pool_id, client_proxy_id, created_at DESC')

      Hmis::Ce::Match::Candidate.
        joins(candidate_pool: { opportunities: { unit: :unit_group } }).
        joins("LEFT JOIN (#{latest_event_subquery.to_sql}) latest_events ON latest_events.candidate_pool_id = ce_match_candidates.candidate_pool_id AND latest_events.client_proxy_id = ce_match_candidates.client_proxy_id").
        select('ce_match_candidates.*, hmis_unit_groups.id AS unit_group_id, latest_events.id AS latest_event_id').
        distinct
    end
  end
end
