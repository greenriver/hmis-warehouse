###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyTwoToTwentyTwentyFour::Project
  class AddRrhSubType
    def process(row)
      row['RRHSubType'] = nil

      row
    end
  end
end
