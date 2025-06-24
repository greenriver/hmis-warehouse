###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  class MatchCandidatesJob < BaseJob
    include NotifierConfig

    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(**args)
      # one-off opportunity, don't track
      return _perform(**args) if args[:opportunity_ids]

      instrument_as_maintenance_task do |run|
        _perform(**args)
        run.complete!
      end
    end

    # @param opportunity_ids [Array] an array of opportunity IDs to build candidate pools for.
    # If nil, builds pools for all active Opportunities
    def _perform(opportunity_ids: nil)
      opportunities = opportunity_ids ? Hmis::Ce::Opportunity.where(id: opportunity_ids) : Hmis::Ce::Opportunity.active
      log("Building candidate pools for #{opportunities.count} opportunities")
      Hmis::Ce::Match::CandidatePoolBuilder.new(opportunities).perform

      # Find candidate pools for these opportunities
      candidate_pool_ids = opportunities.reload.pluck(:candidate_pool_id).compact.uniq
      candidate_pool_scope = Hmis::Ce::Match::CandidatePool.where(id: candidate_pool_ids)
      client_scope = Hmis::Hud::Client.hmis

      log("Running the CE match engine for #{candidate_pool_scope.count} candidate pools")
      candidate_pool_scope.find_each do |pool|
        Hmis::Ce::Match::Engine.call(pool, client_scope)
      end
    end

    def log(message)
      @notifier&.ping("[CandidatePoolBuilderJob] #{message}")
    end
  end
end
