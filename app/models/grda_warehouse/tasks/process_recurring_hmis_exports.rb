###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks
  class ProcessRecurringHmisExports
    def run!
      recurring_exports_scope.each do |export|
        if export.should_run?
          export.run
        end
      end
    end

    def recurring_exports_scope
      GrdaWarehouse::RecurringHmisExport.all
    end
  end
end
