###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Rebuild candidate pools for all unit groups in the background, under the CE maintenance lock.
#
# Runs inside the rake task today, holding the maintenance lock from the cron process for as
# long as it takes to acquire it (up to 5 minutes) plus however long the build takes.
# @see Hmis::Ce::Match::CandidatePoolBuilder
module Hmis::Ce::Match
  class CandidatePoolBuilderJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    queue_with_priority MAINTENANCE_PRIORITY_15

    def perform(...)
      instrument_as_maintenance_task do |run|
        run.complete! if _perform(...)
      end
    end

    def _perform(**args)
      did_run = false
      # lock_for_maintenance!'s transaction-scoped lock is released as soon as its own transaction
      # ends, so it needs an explicit transaction here to stay held for the block's duration -- unlike
      # its other callers, which run inside an AR callback's save transaction already.
      CandidatePool.transaction do
        CandidatePool.lock_for_maintenance!(timeout_seconds: 5.minutes) do
          CandidatePoolBuilder.call(**args)
          did_run = true
        end
      end
      did_run
    end
  end
end
