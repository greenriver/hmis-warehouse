###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyTwoToTwentyTwentyFour::Exit
  class Transforms
    def self.transforms(csv: false, db: false, references: {}) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        HudTwentyTwentyTwoToTwentyTwentyFour::Exit::AddDestinationSubsidyType,
        HudTwentyTwentyTwoToTwentyTwentyFour::Exit::UpdateDestination, # Done last as it overwrites destination
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::Exit
    end
  end
end
