###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
