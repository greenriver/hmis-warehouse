###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyToTwentyTwentyTwo::Service
  class RemoveV3Code11
    def process(row)
      row['TypeProvided'] = 12 if row['TypeProvided']&.to_s == '11'

      row
    end
  end
end
