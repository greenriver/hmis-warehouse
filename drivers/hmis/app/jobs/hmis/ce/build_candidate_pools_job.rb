###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

#
# Hmis::Ce::BuildCandidatePoolsJob
#
# Builds candidate pools for opportunities and marks them as dirty for processing.
#
module Hmis::Ce
  class BuildCandidatePoolsJob < BaseJob
    # @param opportunity_ids [Array<Integer>, nil] IDs of opportunities to process.
    #   If nil, processes all active opportunities.
    def perform(opportunity_ids: nil)
      raise unless Hmis::Ce.configuration.enabled?

      opportunities = opportunity_scope(opportunity_ids)
      return if opportunities.empty?

      dirty_pool_ids = Hmis::Ce::Match::CandidatePoolBuilder.new(opportunities).perform
      if opportunity_ids
        Hmis::Ce::Match::CandidatePool.where(id: dirty_pool_ids).mark_all_dirty if dirty_pool_ids.any?
      else
        # re-process all pools
        Hmis::Ce::Match::CandidatePool.mark_all_dirty
      end
    end

    protected

    def opportunity_scope(opportunity_ids)
      scope = Hmis::Ce::Opportunity.active
      scope = scope.where(id: opportunity_ids) if opportunity_ids
      scope
    end
  end
end
