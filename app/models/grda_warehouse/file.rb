###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class File < GrdaWarehouseBase
    acts_as_paranoid
    belongs_to :user, optional: true
  end
end
