###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyToTwentyTwentyTwo::Export
  class AddCsvVersion
    def process(row)
      row['CSVVersion'] = 'FY2022'
      row
    end
  end
end
