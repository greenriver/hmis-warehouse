# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class MaintenanceTasksLifecycleJob < BaseJob
  include MaintenanceTaskInstrumentation

  def perform
    GrdaWarehouse::Tasks::SystemMaintenanceTask.find_each(&:process_alerts)

    # Clean up expired runs for ALL tasks
    GrdaWarehouse::Tasks::SystemMaintenanceTaskRun.expired.delete_all
  end
end
