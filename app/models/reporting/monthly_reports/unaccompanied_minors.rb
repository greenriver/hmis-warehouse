###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting::MonthlyReports
  class UnaccompaniedMinors < Base

    def enrollment_scope start_date:, end_date:
      enrollment_source.unaccompanied_minors.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'Unaccompanied Minors'
    end

    def sub_population
      :unaccompanied_minors
    end
  end
end