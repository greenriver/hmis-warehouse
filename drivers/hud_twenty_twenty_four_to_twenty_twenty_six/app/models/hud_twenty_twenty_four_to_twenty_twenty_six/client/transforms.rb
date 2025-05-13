###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix::Client
  class Transforms
    def self.transforms(csv: false, db: false, references:) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        HudTwentyTwentyFourToTwentyTwentySix::Client::AddNewColumns,
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::Client
    end
  end
end
