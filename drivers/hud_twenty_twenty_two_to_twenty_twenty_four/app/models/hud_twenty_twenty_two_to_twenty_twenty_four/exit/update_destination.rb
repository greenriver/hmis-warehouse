###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::Exit
  class UpdateDestination
    include HudTwentyTwentyTwoToTwentyTwentyFour::LivingSituationOptions

    def process(row)
      destination = row['Destination'].to_i
      row['Destination2022'] = destination
      new_destination = LIVING_SITUATIONS[destination]
      return row unless new_destination.present?

      row['Destination'] = new_destination

      row
    end
  end
end
