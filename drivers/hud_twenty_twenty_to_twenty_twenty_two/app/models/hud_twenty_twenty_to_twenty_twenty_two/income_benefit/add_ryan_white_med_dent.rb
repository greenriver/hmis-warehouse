###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyToTwentyTwentyTwo::IncomeBenefit
  class AddRyanWhiteMedDent
    def process(row)
      row['RyanWhiteMedDent'] = nil
      row['NoRyanWhiteReason'] = nil

      row
    end
  end
end
