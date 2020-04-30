###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class AdHocAnonAnalysisController < AdHocAnalysisController
    private def report_source
      GrdaWarehouse::WarehouseReports::Exports::AdHocAnon
    end
  end
end
