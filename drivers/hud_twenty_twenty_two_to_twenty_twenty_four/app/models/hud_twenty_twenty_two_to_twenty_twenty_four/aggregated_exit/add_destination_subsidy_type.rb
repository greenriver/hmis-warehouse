###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::AggregatedExit
  class AddDestinationSubsidyType
    include HudTwentyTwentyTwoToTwentyTwentyFour::LivingSituationOptions

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
