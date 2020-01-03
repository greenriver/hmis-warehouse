###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse
  class RecurringHmisExportLink  < GrdaWarehouseBase
    belongs_to :hmis_export
    belongs_to :recurring_hmis_export
  end
end