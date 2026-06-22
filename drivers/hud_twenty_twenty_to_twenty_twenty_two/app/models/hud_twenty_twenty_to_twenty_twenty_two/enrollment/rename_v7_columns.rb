###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyToTwentyTwentyTwo::Enrollment
  class RenameV7Columns
    def process(row)
      row['HOHLeaseholder'] = row['HOHLeasesholder']

      row
    end
  end
end
