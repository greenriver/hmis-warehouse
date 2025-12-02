###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
