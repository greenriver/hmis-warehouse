# frozen_string_literal: true

module Hmis::Ce
  class OpportunityRefresher
    # Close stale opportunities and create fresh ones with updated CE Match Rules
    #
    # @param candidate_pool_ids [Array<Integer>, nil] Optional array of candidate pool IDs to filter by.
    #   If nil, processes ALL stale opportunities across the app.
    # @return [Hash] {
    #   closed_count: Integer,
    #   closed_opportunity_unit_ids: Array<Integer>,
    #   created_count: Integer,
    #   created_opportunity_ids: Array<Integer>,
    # }
    def refresh_stale_opportunities(candidate_pool_ids: nil)
      scope = Hmis::Ce::Opportunity.stale.open

      # Filter by candidate pools if provided
      scope = scope.where(candidate_pool_id: candidate_pool_ids) if candidate_pool_ids.present?

      closed_opportunity_unit_ids = []
      opportunities_to_create = []

      Hmis::Ce::Opportunity.transaction do
        # Step 1: Close stale opportunities and collect unit IDs
        scope.includes(:unit).find_each do |opportunity|
          opportunity.close!
          closed_opportunity_unit_ids << opportunity.unit_id

          # Step 2: Build fresh opportunity for this unit
          opportunities_to_create << opportunity.unit.build_ce_opportunity
        end

        # Step 3: Bulk create new opportunities
        created_ids = []
        if opportunities_to_create.any?
          result = Hmis::Ce::Opportunity.import!(opportunities_to_create)
          created_ids = result.ids
        end

        {
          closed_count: closed_opportunity_unit_ids.length,
          closed_opportunity_unit_ids: closed_opportunity_unit_ids,
          created_count: created_ids.length,
          created_opportunity_ids: created_ids,
        }
      end
    end
  end
end
