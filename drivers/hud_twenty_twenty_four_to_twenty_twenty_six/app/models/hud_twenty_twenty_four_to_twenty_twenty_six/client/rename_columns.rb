###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix::Client
  class RenameColumns
    def process(row)
      row['HispanicLatinao'] = row['HispanicLatinaeo']

      row
    end
  end
end
