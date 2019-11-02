###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reporting::MonthlyReports
  class Juvenile < Base

    def enrollment_scope start_date:, end_date:
      enrollment_source.children_only.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'Juveniles'
    end

    def sub_population
      :juvenile
    end
  end
end