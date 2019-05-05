# A reporting table to power the population dash boards.
# One row per client per sub-population per month.

module Reporting::MonthlyReports
  class Base < ReportingBase
    include ArelHelper
    self.table_name = :warehouse_monthly_reports


    def populate! date_range: '2015-01-01'.to_date..Date.yesterday
      @date_range = date_range
      @start_date = @date_range.first
      @end_date = @date_range.last

      self.class.transaction do
        _clear!
        _populate!
      end
    end

    def _clear!
      self.class.delete_all
    end

    def _populate!
      raise NotImplementedError
    end

    def enrollment_scope
      raise NotImplementedError
    end

    def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment.homeless
    end

  end
end