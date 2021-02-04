###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks
  class ProcessRecurringHmisExports
    def run!
      recurring_exports_scope.each do |export|
        export.run if export.should_run?
      end
    end

    def recurring_exports_scope
      GrdaWarehouse::RecurringHmisExport.all
    end
  end
end
