###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
#

module HudTwentyTwentyToTwentyTwentyTwo::Enrollment
  class FilterLiteralHomelessHistory
    def process(row)
      row['LiteralHomelessHistory'] = filter(row)

      row
    end

    # HUD does not define a mapping for this row, to reduce the number of errors when
    # importing this defines "safe" transforms, and clears other values
    def filter(row)
      return 2 if row['LiteralHomelessHistory']&.to_s == '3' # Replace value for None
      return 99 if row['LiteralHomelessHistory']&.to_s == '99' # Pass 99 through

      return nil # Otherwise clear the field
    end
  end
end
