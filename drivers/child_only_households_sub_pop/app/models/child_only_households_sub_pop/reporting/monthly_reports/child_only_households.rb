###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ChildOnlyHouseholdsSubPop::Reporting::MonthlyReports
  class ChildOnlyHouseholds < ::Reporting::MonthlyReports::Base
    def enrollment_scope(start_date:, end_date:)
      enrollment_source.child_only_households.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'Child only Households'
    end

    def sub_population
      :child_only_households
    end
  end
end
