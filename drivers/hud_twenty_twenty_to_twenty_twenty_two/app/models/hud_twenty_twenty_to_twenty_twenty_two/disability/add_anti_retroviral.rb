###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Disability
  class AddAntiRetroviral
    def process(row)
      row['AntiRetroviral'] = nil

      row
    end
  end
end
