###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyToTwentyTwentyTwo::Service
  class AddMovingOnOtherType
    def process(row)
      row['MovingOnOtherType'] = nil

      row
    end
  end
end
