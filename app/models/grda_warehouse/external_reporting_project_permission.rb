###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::ExternalReportingProjectPermission < GrdaWarehouseBase
  belongs_to :user # X-DB, so you can't join
  belongs_to :project
end
