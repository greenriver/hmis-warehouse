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

  def perform
    instrument_as_maintenance_task do |run|
      with_lock do
        _perform
        run.complete!
      end
    end
  end

  # The hourly rake task re-enqueues this
  def supports_idempotent_retry?
    false
  end

  def _perform
    GrdaWarehouse::ProjectGroup.maintain_project_lists!
    Hmis::ProjectGroup.maintain_project_lists! if HmisEnforcement.hmis_enabled?
  end

  private

  def with_lock(&block)
    lock_name = self.class.name.demodulize
    GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
  end
end
