###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::HealthAndDv
  class RenameDvSurvivor
    def process(row)
      row['DomesticViolenceSurvivor'] = row['DomesticViolenceVictim']

      row
    end
  end
end
