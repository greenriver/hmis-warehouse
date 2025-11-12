###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyToTwentyTwentyTwo::Organization
  class RenameVictimServicesProvider
    def process(row)
      row['VictimServiceProvider'] = row['VictimServicesProvider']

      row
    end
  end
end
