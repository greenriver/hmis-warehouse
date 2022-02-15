###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientsSubPop::Reporting::MonthlyReports
  class Clients < ::Reporting::MonthlyReports::Base
    def enrollment_scope(start_date:, end_date:)
      enrollment_source.clients.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'All Clients'
    end

    def sub_population
      :clients
    end
  end
end
