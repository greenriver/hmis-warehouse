###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::Enrollment
  class AddRentalSubsidyType
    include HudTwentyTwentyTwoToTwentyTwentyFour::LivingSituationOptions

    def process(row)
      row['RentalSubsidyType'] = nil

      situation = row['LivingSituation'].to_i
      subsidy_type = SUBSIDY_TYPES[situation]
      return row unless subsidy_type.present?

      row['RentalSubsidyType'] = subsidy_type

      row
    end
  end
end
