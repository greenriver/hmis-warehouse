module Reporting::MonthlyReports
  class ParentingChildren < Base

    def enrollment_scope start_date:, end_date:
      enrollment_source.parenting_children.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'Parenting Children'
    end

    def sub_population
      :parenting_children
    end
  end
end