###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class HmisExternalApisBase < ::GrdaWarehouseBase
    self.abstract_class = true

    has_paper_trail
  end
end
