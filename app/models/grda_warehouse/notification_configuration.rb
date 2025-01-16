###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# This class holds links between:
# 1. The item that will trigger a notification (source)
# 2. The user who should receive the notification
# 3. The notification type
module GrdaWarehouse
  class NotificationConfiguration < GrdaWarehouseBase
    belongs_to :user # NOTE: this is a cross-database relationship
    belongs_to :source, polymorphic: true
  end
end
