###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyTwoToTwentyTwentyFour::Export
  class UpdateCsvVersion
    def process(row)
      row['CSVVersion'] = '2024 v1.3'

      row
    end
  end
end
