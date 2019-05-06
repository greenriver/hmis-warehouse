module Reporting::MonthlyReports
  class Veteran < Base


    def enrollment_scope start_date:, end_date:
      enrollment_source.veteran.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def active_scope
      enrollment_scope(start_date: @start_date, end_date: @end_date).
        with_service_between(start_date: @start_date, end_date: @end_date)
    end


    # def exit_scope
    #   enrollment_source.veteran.
    #     exit_within_date_range(start_date: @start_date, end_date: @end_date)
    # end

  end
end