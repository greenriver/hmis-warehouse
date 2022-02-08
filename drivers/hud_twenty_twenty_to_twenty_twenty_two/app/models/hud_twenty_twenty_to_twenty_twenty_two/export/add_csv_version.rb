###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Export
  class AddCsvVersion
    def process(row)
      row['CSVVersion'] = 'FY2022'
      row
    end
  end
end
