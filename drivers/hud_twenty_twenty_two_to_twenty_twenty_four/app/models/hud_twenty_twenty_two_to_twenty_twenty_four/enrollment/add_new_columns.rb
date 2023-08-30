###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::Enrollment
  class AddNewColumns
    def process(row)
      row['TranslationNeeded'] = nil
      row['PreferredLanguage'] = nil
      row['PreferredLanguageDifferent'] = nil

      row
    end
  end
end
