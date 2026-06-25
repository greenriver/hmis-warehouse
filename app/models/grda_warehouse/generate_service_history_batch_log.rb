###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class GrdaWarehouse::GenerateServiceHistoryBatchLog < GrdaWarehouseBase
  include ActionView::Helpers::DateHelper
    belongs_to :generate_service_history_log

end
