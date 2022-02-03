###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module VeteransSubPop::Reporting::MonthlyReports
  class Veterans < ::Reporting::MonthlyReports::Base
    def enrollment_scope(start_date:, end_date:)
      enrollment_source.veterans.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'Veterans'
    end

    def sub_population
      :veterans
    end
  end
end
