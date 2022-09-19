###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AccessLogs
  class Export < ::GrdaWarehouse::DocumentExport
    def authorized?
      true
    end

    def report_class
      AccessLogs::Report
    end
  end
end
