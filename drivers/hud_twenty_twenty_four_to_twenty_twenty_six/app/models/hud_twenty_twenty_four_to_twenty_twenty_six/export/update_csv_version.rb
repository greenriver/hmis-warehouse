###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix::Export
  class UpdateCsvVersion
    def process(row)
      row['CSVVersion'] = '2026 v1.0'

      row
    end
  end
end
