###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix::AggregatedExit
  class UpdateDestination
    include HudTwentyTwentyFourToTwentyTwentySix::LivingSituationOptions

    def process(row)
      destination = row['Destination'].to_i
      new_destination = LIVING_SITUATIONS[destination]
      return row unless new_destination.present?

      row['Destination'] = new_destination

      row
    end
  end
end
