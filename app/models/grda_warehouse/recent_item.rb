###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class RecentItem < GrdaWarehouseBase
    belongs_to :owner, polymorphic: true
    belongs_to :item, polymorphic: true
  end
end
