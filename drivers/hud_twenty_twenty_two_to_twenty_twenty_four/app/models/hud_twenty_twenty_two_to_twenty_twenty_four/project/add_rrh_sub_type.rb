###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::Project
  class AddRrhSubType
    def process(row)
      row['RRHSubType'] = nil

      row
    end
  end
end
