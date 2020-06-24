###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting::MonthlyReports
  class Parents < Base

    def enrollment_scope start_date:, end_date:
      enrollment_source.family_parents.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'Parents'
    end

    def sub_population
      :family_parents
    end
  end
end