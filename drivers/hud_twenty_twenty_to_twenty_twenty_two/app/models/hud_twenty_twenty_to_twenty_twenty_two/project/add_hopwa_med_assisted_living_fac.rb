###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
#

module HudTwentyTwentyToTwentyTwentyTwo::Project
  class AddHopwaMedAssistedLivingFac
    def process(row)
      row['HOPWAMedAssistedLivingFac'] = nil

      row
    end
  end
end
