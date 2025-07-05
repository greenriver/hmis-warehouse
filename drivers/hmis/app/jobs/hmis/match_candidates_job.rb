###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

#
# The job runs nightly over all candidate pools and clients. And be run ad-hoc for specific pools
# * Update matches for the given pool(s) or all pools if none-specified
# * Synchronization relies on the advisory lock within Hmis::Ce::Match::Engine, avoiding simultaneous processing of the same pool
# * The job is willing to wait to acquire the lock for a given pool
# * Failure to process all pools is an exception, which should cause the job to be retried based on retry configuration
# * See also ProcessClientChangeMarkersJob
#
module Hmis
  class MatchCandidatesJob < BaseJob
    include NotifierConfig

    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(**args)
      # one-off opportunity, don't track
      return _perform(**args) if args[:opportunity_ids]

      # Full-scan
      instrument_as_maintenance_task do |run|
        _perform(**args)
        run.complete!
      end
    end

    # @param opportunity_ids [Array] an array of opportunity IDs to build candidate pools for.
    # If nil, builds pools for all active Opportunities
    def _perform(opportunity_ids: nil, lock_timeout_seconds: 300)
      raise unless Hmis::Ce.configuration.enabled?

      opportunities = opportunity_ids ? Hmis::Ce::Opportunity.where(id: opportunity_ids) : Hmis::Ce::Opportunity.active
      log("Building candidate pools for #{opportunities.count} opportunities")
      Hmis::Ce::Match::CandidatePoolBuilder.new(opportunities).perform

      # Find candidate pools for these opportunities
      candidate_pool_ids = opportunities.reload.pluck(:candidate_pool_id).compact.uniq
      candidate_pool_scope = Hmis::Ce::Match::CandidatePool.where(id: candidate_pool_ids)
      client_scope = ::GrdaWarehouse::Hud::Client.destination

      log("Running the CE match engine for #{candidate_pool_scope.count} candidate pools")
      candidate_pool_scope.find_each do |pool|
        completed = Hmis::Ce::Match::Engine.call(pool, client_scope, lock_timeout_seconds: lock_timeout_seconds)
        raise "Failed acquire lock for CE candidate pool #{pool.id}" unless completed
      end
    end

    def log(message)
      @notifier&.ping("[CandidatePoolBuilderJob] #{message}")
    end
  end
end
