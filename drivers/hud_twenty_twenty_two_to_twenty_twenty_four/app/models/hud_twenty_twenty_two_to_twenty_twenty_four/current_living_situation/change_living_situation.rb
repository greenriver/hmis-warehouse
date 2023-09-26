###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::CurrentLivingSituation
  class ChangeLivingSituation
    include HudTwentyTwentyTwoToTwentyTwentyFour::LivingSituationOptions

    def process(row)
      situation = row['CurrentLivingSituation'].to_i
      row['LivingSituation2022'] = situation
      new_situation = LIVING_SITUATIONS[situation]
      return row unless new_situation.present?

      row['CurrentLivingSituation'] = new_situation

      row
    end
  end
end
