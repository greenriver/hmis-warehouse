###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
#

module HudTwentyTwentyToTwentyTwentyTwo::Export
  class AddCsvVersion
    def process(row)
      row['CSVVersion'] = '2022'
      row
    end
  end
end
