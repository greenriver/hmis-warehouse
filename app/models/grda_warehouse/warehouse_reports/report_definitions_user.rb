###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports
  class ReportDefinitionsUser < GrdaWarehouseBase
    belongs_to :report_definition, optional: true
  end
end
