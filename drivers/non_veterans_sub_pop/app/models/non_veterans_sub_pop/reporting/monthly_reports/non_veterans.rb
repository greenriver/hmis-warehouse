###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module NonVeteransSubPop::Reporting::MonthlyReports
  class NonVeterans < ::Reporting::MonthlyReports::Base
    def enrollment_scope(start_date:, end_date:)
      enrollment_source.non_veterans.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'Non-Veteran'
    end

    def sub_population
      :non_veterans
    end
  end
end
