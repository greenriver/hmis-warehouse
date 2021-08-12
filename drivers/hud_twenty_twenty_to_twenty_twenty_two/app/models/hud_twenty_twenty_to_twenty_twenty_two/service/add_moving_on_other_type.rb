###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
#

module HudTwentyTwentyToTwentyTwentyTwo::Service
  class AddMovingOnOtherType
    def process(row)
      row['MovingOnOtherType'] = nil

      row
    end
  end
end
