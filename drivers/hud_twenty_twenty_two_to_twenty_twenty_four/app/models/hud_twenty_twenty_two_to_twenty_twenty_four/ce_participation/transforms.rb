###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyTwoToTwentyTwentyFour::CeParticipation
  class Transforms
    def self.transforms(csv: false, db: false, references: {}) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        [HudTwentyTwentyTwoToTwentyTwentyFour::CeParticipation::CreateCeParticipation, references],
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::CeParticipation
    end
  end
end
