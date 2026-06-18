###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Tasks
  class ProcessRecurringHmisExports
    include MaintenanceTaskInstrumentation

    def run!
      instrument_as_maintenance_task do |task_run|
        recurring_exports_scope.each do |export|
          if export.should_run?
            export.run
          end
        end
        task_run.complete!
      end
    end

    def recurring_exports_scope
      GrdaWarehouse::RecurringHmisExport.all
    end
  end
end
