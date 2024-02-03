###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Favorite < GrdaWarehouseBase
  belongs_to :user
  belongs_to :entity, polymorphic: true
end
