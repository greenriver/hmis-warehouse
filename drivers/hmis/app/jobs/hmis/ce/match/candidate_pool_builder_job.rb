###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Rebuild candidate pools for all unit groups, under the CE maintenance lock.
#
# Enqueued from the hourly rake task so the cron process doesn't wait on the lock (up to 5
# minutes) plus however long the build takes. If another holder has the lock,
# lock_for_maintenance! raises WithAdvisoryLock::FailedToAcquireLock, so a contending copy fails
# and is retried by Delayed::Job rather than silently doing nothing.
# @see Hmis::Ce::Match::CandidatePoolBuilder
module Hmis::Ce::Match
  class CandidatePoolBuilderJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    queue_with_priority MAINTENANCE_PRIORITY_15

    def perform(...)
      instrument_as_maintenance_task do |run|
        _perform(...)
        run.complete!
      end
    end

    def _perform(**args)
      # lock_for_maintenance!'s transaction-scoped lock is released as soon as its own transaction
      # ends, so it needs an explicit transaction here to stay held for the block's duration -- unlike
      # its other callers, which run inside an AR callback's save transaction already.
      CandidatePool.transaction do
        CandidatePool.lock_for_maintenance!(timeout_seconds: 5.minutes) do
          CandidatePoolBuilder.call(**args)
        end
      end
    end
  end
end
