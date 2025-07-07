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

      if opportunity_ids
        opportunities = Hmis::Ce::Opportunity.where(id: opportunity_ids)
      else
        opportunities = Hmis::Ce::Opportunity.active
      end

      return if opportunities.empty?

      dirty_pool_ids = Hmis::Ce::Match::CandidatePoolBuilder.new(opportunities).perform
      if opportunity_ids
        Hmis::Ce::Match::CandidatePool.where(id: dirty_pool_ids).mark_all_dirty if dirty_pool_ids.any?
      else
        # re-process all pools
        Hmis::Ce::Match::CandidatePool.mark_all_dirty
      end
    end
  end
end
