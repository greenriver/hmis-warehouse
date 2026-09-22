###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class SyncAnalysisDataJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
  queue_with_priority MAINTENANCE_PRIORITY_15

  def perform(...)
    GrdaWarehouse::Tasks::SyncAnalysisDataTask.perform(...)
  end

  # The hourly rake task re-enqueues this
  def supports_idempotent_retry?
    false
  end
end
