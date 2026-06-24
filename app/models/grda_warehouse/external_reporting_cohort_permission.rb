###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class GrdaWarehouse::ExternalReportingCohortPermission < GrdaWarehouseBase
  belongs_to :user # X-DB, so you can't join
  belongs_to :cohort
end
