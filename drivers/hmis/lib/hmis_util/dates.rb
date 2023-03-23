###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
module HmisUtil
  class Dates
    def self.safe_parse_date(date_string:, date_format: '%Y-%m-%d')
      date = begin
        Date.strptime(date_string, date_format)
      rescue ArgumentError
        return nil
      end

      date
    end
  end
end
