###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class RecurringHmisExportLink  < GrdaWarehouseBase
    belongs_to :hmis_export, optional: true
    belongs_to :recurring_hmis_export, optional: true
  end
end
