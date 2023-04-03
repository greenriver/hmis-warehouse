###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::HmisBase < GrdaWarehouseBase
  self.abstract_class = true

  has_paper_trail
end
