###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Organization
  class RenameVictimServicesProvider
    def process(row)
      row['VictimServiceProvider'] = row['VictimServicesProvider']

      row
    end
  end
end
