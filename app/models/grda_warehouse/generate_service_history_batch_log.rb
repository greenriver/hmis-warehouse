###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class GrdaWarehouse::GenerateServiceHistoryBatchLog < GrdaWarehouseBase
  include ActionView::Helpers::DateHelper
    belongs_to :generate_service_history_log

end