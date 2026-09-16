###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Refreshes project group membership for both the warehouse and HMIS project group models in the
# background. Neither underlying maintain_project_lists! has its own lock, so a concurrent copy of
# this job (e.g. hour N still running when hour N+1 enqueues) would race to rewrite the same join
# tables; the advisory lock here makes a second concurrent copy a no-op instead.
# @see GrdaWarehouse::ProjectGroup.maintain_project_lists!
# @see Hmis::ProjectGroup.maintain_project_lists!
class MaintainProjectGroupListsJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
  queue_with_priority MAINTENANCE_PRIORITY_15

  LOCK_NAME = 'maintain_project_group_lists'

  def perform(...)
    instrument_as_maintenance_task do |run|
      run.complete! if _perform(...)
    end
  end

  def _perform
    did_run = false
    GrdaWarehouseBase.with_advisory_lock(LOCK_NAME, timeout_seconds: 0) do
      GrdaWarehouse::ProjectGroup.maintain_project_lists!
      Hmis::ProjectGroup.maintain_project_lists! if HmisEnforcement.hmis_enabled?
      did_run = true
    end
    did_run
  end
end
