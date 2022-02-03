###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#
# Code initially written for and funded by Delaware Health and Social Services.
# Used and modified with permission.

module GrdaWarehouse
  module UsCensusApi
    class CensusGroup < GrdaWarehouseBase
      def variables
        CensusVariable.where(dataset: self.dataset, year: self.year, census_group: self.name)
      end
    end
  end
end
