###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module YouthParentsSubPop::Reporting::MonthlyReports
  class YouthParents < ::Reporting::MonthlyReports::Base


    def enrollment_scope start_date:, end_date:
      enrollment_source.all.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'Youth Parents'
    end

    def sub_population
      :youth_parents
    end
  end
end