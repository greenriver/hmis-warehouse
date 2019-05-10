module Reporting::MonthlyReports
  class Children < Base

    def enrollment_scope start_date:, end_date:
      enrollment_source.children_only.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'Children'
    end

    def sub_population
      :children
    end
  end
end