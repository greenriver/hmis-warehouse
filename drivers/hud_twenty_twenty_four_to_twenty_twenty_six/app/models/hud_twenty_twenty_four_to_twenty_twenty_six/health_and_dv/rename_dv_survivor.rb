###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix::HealthAndDv
  class RenameDvSurvivor
    def process(row)
      row['DomesticViolenceSurvivor'] = row['DomesticViolenceVictim']

      row
    end
  end
end
