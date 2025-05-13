###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix::Export
  class AddImplementationId
    def process(row)
      implementation_id = "#{row['SourceID'].presence} #{row['SourceName'].presence}"
      row['ImplementationID'] = implementation_id

      row
    end
  end
end
