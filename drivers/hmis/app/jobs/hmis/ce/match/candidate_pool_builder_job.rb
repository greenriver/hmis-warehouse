###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
      # ends, so it needs an explicit transaction here to stay held for the block's duration
      CandidatePool.transaction do
        CandidatePool.lock_for_maintenance!(timeout_seconds: 5.minutes) do
          CandidatePoolBuilder.call(**args)
        end
      end
    end
  end
end
