###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::Export
  class UpdateCsvVersion
    def process(row)
      row['CSVVersion'] = '2024 v1.3'

      row
    end
  end
end
