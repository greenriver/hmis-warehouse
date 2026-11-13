###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class MaintenanceTasksLifecycleJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  def perform
    GrdaWarehouse::Tasks::SystemMaintenanceTask.find_each(&:process_alerts)

    # Clean up expired runs for ALL tasks
    GrdaWarehouse::Tasks::SystemMaintenanceTaskRun.expired.delete_all
  end
end
