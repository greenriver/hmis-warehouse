###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Base < ::GrdaWarehouseBase
  self.abstract_class = true

  acts_as_paranoid(column: :DateDeleted)
end
