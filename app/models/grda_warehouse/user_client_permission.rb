###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class GrdaWarehouse::UserClientPermission < GrdaWarehouseBase
  belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
  validates :user_id, presence: true
end
