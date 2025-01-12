# an eligible, prioritized client for a given policy
module Hmis::Ce::Match
  class Candidate < GrdaWarehouseBase
    self.table_name = 'ce_match_candidates'
    belongs_to :candidate_pool, class_name: 'Hmis::Ce::Match::CandidatePool'
    belongs_to :client, class_name: 'Hmis::Hud::Client'

    # FIXME: permissions
    scope :viewable_by, ->(_user) { all }

    # order by descending priority, NULL values last. Use id as a tie-breaker
    scope :prioritized, -> {
      order(
        Arel::Nodes::Descending.new(arel_table[:priority_score]).nulls_last,
        arel_table[:id].asc,
      )
    }

    # Which candidates (clients) are eligible for an opportunity
    # - Filter out candidates that have already been referred to this opportunity.
    # - Filter out candidates with an active referral to another opportunity with overlapping categories.
    scope :for_opportunity, ->(opportunity) {
      scope = opportunity.pool.candidates

      # do we need to allow a referral to be re-started for the same client/opportunity?
      scope = scope.where.not(client_id: opportunity.referrals.select(:client_id))

      # clients with active referrals to other opportunities who's categories overlap with this opportunity
      exclude_client_ids = Referral.active.
        joins(opportunities: :categories).
        where.not(opportunities: { id: opportunity.id }). # not this opportunity
        where(categories: { id: opportunity.categories.id }). # overlapping categories
        distinct.pluck(:client_id)

      scope = scope.where.not(client_id: exclude_client_ids)
      scope
    }
  end
end
