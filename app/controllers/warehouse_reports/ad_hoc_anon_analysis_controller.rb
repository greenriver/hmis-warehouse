###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class AdHocAnonAnalysisController < AdHocAnalysisController
    private def report_source
      GrdaWarehouse::WarehouseReports::Exports::AdHocAnon
    end
  end
end
