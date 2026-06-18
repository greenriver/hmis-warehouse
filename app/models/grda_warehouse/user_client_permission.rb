###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class GrdaWarehouse::UserClientPermission < GrdaWarehouseBase
  belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
  validates :user_id, presence: true
end
