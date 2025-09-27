###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::WarehouseReports
  class ReportDefinitionsUser < GrdaWarehouseBase
    belongs_to :report_definition, optional: true
  end
end
