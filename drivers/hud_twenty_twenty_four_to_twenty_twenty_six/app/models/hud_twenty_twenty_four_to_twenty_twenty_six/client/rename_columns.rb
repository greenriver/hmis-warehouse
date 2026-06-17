###
# Copyright Green River Data Group, Inc.
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
