###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Favorite < GrdaWarehouseBase
  belongs_to :user
  belongs_to :entity, polymorphic: true
end
