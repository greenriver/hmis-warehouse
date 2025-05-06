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

    # @param opportunities an ActiveRecord::Scope of Hmis::Ce::Opportunity records to build candidate pools for.
    # If nil, builds pools for all active Opportunities
    # @param backoff_time [ActiveSupport::Duration] if provided, the job will _not_ re-run the match engine for
    # candidate pools that have had candidates generated within the backoff_time.
    def perform(opportunities: nil, backoff_time: nil)
      opportunities ||= Hmis::Ce::Opportunity.active
      opportunity_ids = opportunities.pluck(:id)
      log("Building candidate pools for #{opportunities.count} opportunities")
      Hmis::Ce::Match::CandidatePoolBuilder.new(opportunities).perform

      client_scope = Hmis::Hud::Client.hmis
      # Find candidate pools for the opportunities
      candidate_pool_ids = Hmis::Ce::Opportunity.where(id: opportunity_ids).pluck(:candidate_pool_id).compact.uniq
      candidate_pool_scope = Hmis::Ce::Match::CandidatePool.where(id: candidate_pool_ids)

      # If backoff_time was provided, only call the match engine for candidate pools that have not been updated since backoff_time
      cp_t = Hmis::Ce::Match::CandidatePool.arel_table
      candidate_pool_scope = candidate_pool_scope.where(cp_t[:candidates_generated_at].lt(Time.current - backoff_time)) if backoff_time

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
