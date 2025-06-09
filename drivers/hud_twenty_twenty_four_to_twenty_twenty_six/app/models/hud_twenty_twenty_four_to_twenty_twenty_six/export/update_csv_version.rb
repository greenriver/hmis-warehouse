###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
