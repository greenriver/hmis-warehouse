###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyTwoToTwentyTwentyFour::Enrollment
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
