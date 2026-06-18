###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyTwoToTwentyTwentyFour::IncomeBenefit
  class RenameVaColumns
    def process(row)
      row['VHAServices'] = row['VAMedicalServices']
      row['NoVHAReason'] = row['NoVAMedReason']

      row
    end
  end
end
