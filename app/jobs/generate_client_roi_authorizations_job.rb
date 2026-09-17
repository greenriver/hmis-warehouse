###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Rebuild ROI authorization records for destination clients in the background.
#
# The full scan is slow enough to hold up the rest of the hourly rake task, so it runs here instead.
# @see GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask
class GenerateClientRoiAuthorizationsJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
  queue_with_priority MAINTENANCE_PRIORITY_15

  def perform(...)
    GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.perform(...)
  end

  # The work itself is idempotent, but a single bad client raises part way through, and retrying re-runs
  # the entire scan to hit the same client again
  def supports_idempotent_retry?
    false
  end
end
