###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix::Enrollment
  class AddNewColumns
    def process(row)
      row['TranslationNeeded'] = nil
      row['PreferredLanguage'] = nil
      row['PreferredLanguageDifferent'] = nil

      row
    end
  end
end
