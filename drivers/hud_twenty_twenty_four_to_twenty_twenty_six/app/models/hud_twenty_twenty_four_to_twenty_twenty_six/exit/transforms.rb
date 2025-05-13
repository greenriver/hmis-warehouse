###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix::Exit
  class Transforms
    def self.transforms(csv: false, db: false, references: {}) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        HudTwentyTwentyFourToTwentyTwentySix::Exit::AddDestinationSubsidyType,
        HudTwentyTwentyFourToTwentyTwentySix::Exit::UpdateDestination, # Done last as it overwrites destination
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::Exit
    end
  end
end
