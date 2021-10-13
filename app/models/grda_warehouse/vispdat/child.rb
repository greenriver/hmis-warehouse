###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Vispdat
  class Child < GrdaWarehouseBase
    belongs_to :family, optional: true
  end
end
