# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks
  class ProcessRecurringHmisExports
    include MaintenanceTaskInstrumentation

    def run!
      instrument_as_maintenance_task('run!') do |task_run|
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
