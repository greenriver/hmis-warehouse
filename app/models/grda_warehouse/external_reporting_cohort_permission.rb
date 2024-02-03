###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::ExternalReportingCohortPermission < GrdaWarehouseBase
  belongs_to :user # X-DB, so you can't join
  belongs_to :cohort
end
