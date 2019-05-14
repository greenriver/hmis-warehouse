module Reporting::MonthlyReports
  class IndividualAdults < Base

    def enrollment_scope start_date:, end_date:
      enrollment_source.individual_adults.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'Individual Adults'
    end

    def sub_population
      :individual_adults
    end
  end
end