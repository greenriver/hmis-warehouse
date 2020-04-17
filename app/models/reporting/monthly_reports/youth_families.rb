###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reporting::MonthlyReports
  class YouthFamilies < Base

    def enrollment_scope start_date:, end_date:
      enrollment_source.youth_families.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'Youth Families'
    end

    def sub_population
      :youth_families
    end
  end
end