# frozen_string_literal: true

module Hmis::Ce
  class OpportunityRefresher
    # Close stale opportunities and create fresh ones with updated CE Match Rules
    #
    # @param candidate_pool_ids [Array<Integer>, nil] Optional array of candidate pool IDs to filter by.
    #   If nil, processes ALL stale opportunities across the app.
    # @return [Hash] {
    #   num_refreshed_units: Integer,
    #   refreshed_unit_ids: Array<Integer>,
    #   created_opportunity_ids: Array<Integer>,
    # }
    def refresh_stale_opportunities(candidate_pool_ids: nil)
      scope = Hmis::Ce::Opportunity.stale.open

      # Filter by candidate pools if provided
      unless candidate_pool_ids.nil?
        candidate_pools = Hmis::Ce::Match::CandidatePool.where(id: candidate_pool_ids)
        raise 'Invalid candidate_pool_ids passed to OpportunityRefresher' unless candidate_pools.size == candidate_pool_ids.size

        scope = scope.where(candidate_pool_id: candidate_pool_ids)
      end

      unit_ids = []
      opportunities_to_create = []

      Hmis::Ce::Opportunity.transaction do
        # Step 1: Close stale opportunities and collect unit IDs
        scope.includes(:unit).find_each do |opportunity|
          opportunity.close!
          unit_ids << opportunity.unit_id

          # Step 2: Build fresh opportunity for this unit
          opportunities_to_create << opportunity.unit.build_ce_opportunity
        end

        # Step 3: Bulk create new opportunities
        created_ids = []
        if opportunities_to_create.any?
          result = Hmis::Ce::Opportunity.import!(opportunities_to_create)
          created_ids = result.ids
        end

        raise 'OpportunityRefresher should create the same number of opportunities as it closes' if unit_ids.uniq.size != created_ids.size

        {
          num_refreshed_units: unit_ids.length,
          refreshed_unit_ids: unit_ids,
          created_opportunity_ids: created_ids,
        }
      end
    end
  end
end
