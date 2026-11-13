###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class SystemCohortsJob < BaseJob
  include NotifierConfig

  attr_accessor :send_notifications
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  def initialize
    setup_notifier('SystemCohorts')
    super
  end

  def perform(...)
    return unless GrdaWarehouse::Config.get(:enable_system_cohorts)

    instrument_as_maintenance_task do |run|
      run.complete! if _perform(...)
    end
  end

  def _perform
    @notifier.ping('Processing system cohorts') if @send_notifications

    lock_name = self.class.name
    did_run = false
    GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0) do
      GrdaWarehouse::SystemCohorts::Base.update_all_system_cohorts
      did_run = true
    end
    return did_run unless @send_notifications

    if did_run
      @notifier.ping('Processed system cohorts')
    else
      @notifier.ping('Could not acquire advisory lock for SystemCohortsJob, another job is already running')
    end
    did_run
  end
end
