###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::IncomeBenefit
  class RenameVaColumns
    def process(row)
      row['VHAServices'] = row['VAMedicalServices']
      row['NoVHAReason'] = row['NoVAMedReason']

      row
    end
  end
end
