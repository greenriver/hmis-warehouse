# frozen_string_literal: true

# an eligible, prioritized client for a given candidate pool
module Hmis::Ce::Match
  class Candidate < GrdaWarehouseBase
    self.table_name = 'ce_match_candidates'
    belongs_to :candidate_pool, class_name: 'Hmis::Ce::Match::CandidatePool'
    belongs_to :client, class_name: 'Hmis::Hud::Client'

    # TODO(#7395): permissions
    scope :viewable_by, ->(_user) { all }

    # order by descending priority, NULL values last. Use id as a tie-breaker
    scope :prioritized, -> {
      order(
        arel_table[:priority_score].desc.nulls_last,
        arel_table[:id].asc,
      )
    }

    # Which candidates (clients) are eligible for an opportunity
    # - Filter out candidates that have already been referred to this opportunity.
    # - Filter out candidates with an active referral to another opportunity with overlapping categories.
    scope :for_opportunity, ->(opportunity) {
      return Hmis::Ce::Opportunity.none unless opportunity.candidate_pool

      scope = opportunity.candidate_pool.candidates

      # do we need to allow a referral to be re-started for the same client/opportunity?
      scope = scope.where.not(client_id: opportunity.referrals.select(:client_id))

      # clients with active referrals to other opportunities whose categories overlap with this opportunity
      exclude_client_ids = Hmis::Ce::Referral.active.
        joins(opportunity: :categories).
        where.not(opportunity: { id: opportunity.id }). # not this opportunity
        where(categories: { id: opportunity.categories.select(:id) }). # overlapping categories
        distinct.pluck(:client_id)

      scope = scope.where.not(client_id: exclude_client_ids)
      scope
    }
  end
end
