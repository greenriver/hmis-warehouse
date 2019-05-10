module Reporting::MonthlyReports
  class ParentingYouth < Base

    def enrollment_scope start_date:, end_date:
      enrollment_source.parenting_youth.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'Parenting Youth'
    end

    def sub_population
      :parenting_youth
    end
  end
end