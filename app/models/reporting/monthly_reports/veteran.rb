###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reporting::MonthlyReports
  class Veteran < Base

    def enrollment_scope start_date:, end_date:
      enrollment_source.veteran.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'Veteran'
    end

    def sub_population
      :veteran
    end
  end
end