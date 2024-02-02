###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::Export
  class AddImplementationId
    def process(row)
      implementation_id = "#{row['SourceID'].presence} #{row['SourceName'].presence}"
      row['ImplementationID'] = implementation_id

      row
    end
  end
end
