###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix::Enrollment
  class AddRentalSubsidyType
    include HudTwentyTwentyFourToTwentyTwentySix::LivingSituationOptions

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
