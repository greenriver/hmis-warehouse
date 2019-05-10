module Reporting::MonthlyReports
  class Youth < Base

    def enrollment_scope start_date:, end_date:
      enrollment_source.unaccompanied_youth.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'Youth'
    end

    def sub_population
      :youth
    end
  end
end