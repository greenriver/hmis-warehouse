###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reporting::MonthlyReports
  class Family < Base

    def enrollment_scope start_date:, end_date:
      enrollment_source.family.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'Family'
    end

    def sub_population
      :family
    end
  end
end