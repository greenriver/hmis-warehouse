###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reporting::MonthlyReports
  class NonVeteran < Base

    def enrollment_scope start_date:, end_date:
      enrollment_source.non_veteran.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'Non-Veteran'
    end

    def sub_population
      :non_veteran
    end
  end
end