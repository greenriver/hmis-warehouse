###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Enrollment
  class RenameR13Columns
    def process(row)
      row['MentalHealthDisorderFam'] = row['MentalHealthIssuesFam']
      row['AlcoholDrugUseDisorderFam'] = row['AlcoholDrugAbuseFam']

      row
    end
  end
end
