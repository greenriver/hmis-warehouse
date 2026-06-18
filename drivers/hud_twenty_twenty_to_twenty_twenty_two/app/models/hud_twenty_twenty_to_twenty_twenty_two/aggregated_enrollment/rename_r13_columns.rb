###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyToTwentyTwentyTwo::AggregatedEnrollment
  class RenameR13Columns
    def process(row)
      row['MentalHealthDisorderFam'] = row['MentalHealthIssuesFam']
      row['AlcoholDrugUseDisorderFam'] = row['AlcoholDrugAbuseFam']

      row
    end
  end
end
