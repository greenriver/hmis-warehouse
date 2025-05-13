###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix::Exit
  class AddDestinationSubsidyType
    include HudTwentyTwentyFourToTwentyTwentySix::LivingSituationOptions

    def process(row)
      row['DestinationSubsidyType'] = nil

      destination = row['Destination'].to_i
      subsidy_type = SUBSIDY_TYPES[destination]
      return row unless subsidy_type.present?

      row['DestinationSubsidyType'] = subsidy_type

      row
    end
  end
end
