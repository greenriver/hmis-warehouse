###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::CurrentLivingSituation
  class AddSubsidyType
    SUBSIDY_TYPES = {
      28 => 428,
      19 => 419,
      31 => 431,
      34 => 433,
      20 => 434,
      3 => 420,
    }.freeze

    def process(row)
      row['CLSSubsidyType'] = nil

      situation = row['CurrentLivingSituation'].to_i
      subsidy_type = SUBSIDY_TYPES[situation].to_s
      return row unless subsidy_type.present?

      row['CLSSubsidyType'] = subsidy_type

      row
    end
  end
end
