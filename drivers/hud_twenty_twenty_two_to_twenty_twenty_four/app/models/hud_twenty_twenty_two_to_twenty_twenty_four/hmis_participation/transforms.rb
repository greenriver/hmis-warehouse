###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::HmisParticipation
  class Transforms
    def self.transforms(csv: false, db: false, references: {}) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        [HudTwentyTwentyTwoToTwentyTwentyFour::HmisParticipation::CreateHmisParticipation, references],
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::HmisParticipation
    end
  end
end
