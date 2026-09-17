###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
