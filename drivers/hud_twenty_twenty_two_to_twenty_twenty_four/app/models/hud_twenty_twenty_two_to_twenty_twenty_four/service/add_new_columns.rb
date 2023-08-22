###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::Service
  class AddNewColumns
    def process(row)
      row['FAStartDate'] = nil
      row['FAEndDate'] = nil

      row
    end
  end
end
