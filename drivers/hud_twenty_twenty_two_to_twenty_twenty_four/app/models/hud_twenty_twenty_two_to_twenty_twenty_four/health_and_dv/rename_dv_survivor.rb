###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyTwoToTwentyTwentyFour::HealthAndDv
  class RenameDvSurvivor
    def process(row)
      row['DomesticViolenceSurvivor'] = row['DomesticViolenceVictim']

      row
    end
  end
end
