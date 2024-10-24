###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::AggregatedEnrollment
  class ChangeLivingSituation
    include HudTwentyTwentyTwoToTwentyTwentyFour::LivingSituationOptions

    def process(row)
      situation = row['LivingSituation'].to_i
      new_situation = LIVING_SITUATIONS[situation]
      return row unless new_situation.present?

      row['LivingSituation'] = new_situation

      row
    end
  end
end
