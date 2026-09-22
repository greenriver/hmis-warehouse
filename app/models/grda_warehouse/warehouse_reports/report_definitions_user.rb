###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# See: docs/domain-pack/warehouse/reports-framework.md
module GrdaWarehouse::WarehouseReports
  class ReportDefinitionsUser < GrdaWarehouseBase
    belongs_to :report_definition, optional: true
  end
end
