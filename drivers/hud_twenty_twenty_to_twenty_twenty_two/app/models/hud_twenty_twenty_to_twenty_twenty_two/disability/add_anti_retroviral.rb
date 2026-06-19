###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyToTwentyTwentyTwo::Disability
  class AddAntiRetroviral
    def process(row)
      row['AntiRetroviral'] = nil

      row
    end
  end
end
