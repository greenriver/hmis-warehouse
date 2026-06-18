###
# Copyright Green River Data Group, Inc.
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
