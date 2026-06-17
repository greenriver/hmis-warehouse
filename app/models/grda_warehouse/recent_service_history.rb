###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class RecentServiceHistory < GrdaWarehouseBase
    self.table_name = :recent_service_history

    def readonly?
      true
    end

  end
end
