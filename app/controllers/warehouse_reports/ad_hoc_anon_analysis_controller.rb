###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module WarehouseReports
  class AdHocAnonAnalysisController < AdHocAnalysisController
    private def report_source
      GrdaWarehouse::WarehouseReports::Exports::AdHocAnon
    end
  end
end
