###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyTwoToTwentyTwentyFour::Service
  class AddNewColumns
    def process(row)
      row['FAStartDate'] = nil
      row['FAEndDate'] = nil

      row
    end
  end
end
