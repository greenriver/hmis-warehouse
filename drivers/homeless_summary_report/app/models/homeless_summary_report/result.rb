###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HomelessSummaryReport
  class Result < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :report
  end
end
