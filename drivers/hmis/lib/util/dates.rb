###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
module Util
  class Dates
    def self.safe_parse_date(date_string:, date_format: '%Y-%m-%d', reasonable_years_distance: 100)
      date = begin
        Date.strptime(date_string, date_format)
      rescue ArgumentError
        return nil
      end

      return nil if (date.year - Date.today.year).abs > reasonable_years_distance

      date
    end
  end
end
