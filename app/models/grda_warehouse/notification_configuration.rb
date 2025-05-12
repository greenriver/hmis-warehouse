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

    def available_users
      possible_users.where.not(id: unavailable_user_ids)
    end

    private def possible_users
      User.active.not_system.order(last_name: :asc, first_name: :asc)
    end

    private def unavailable_user_ids
      self.class.where(source: source, notification_slug: notification_slug).pluck(:user_id) - [user_id]
    end
  end
end
