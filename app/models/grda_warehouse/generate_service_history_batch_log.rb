###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::GenerateServiceHistoryBatchLog < GrdaWarehouseBase
  include ActionView::Helpers::DateHelper
    belongs_to :generate_service_history_log, optional: true

end
