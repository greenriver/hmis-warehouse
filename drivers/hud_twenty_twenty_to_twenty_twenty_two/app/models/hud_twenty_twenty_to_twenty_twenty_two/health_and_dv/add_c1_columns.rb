###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::HealthAndDv
  class AddC1Columns
    def process(row)
      row['LifeValue'] = nil
      row['SupportFromOthers'] = nil
      row['BounceBack'] = nil
      row['FeelingFrequency'] = nil

      row
    end
  end
end
