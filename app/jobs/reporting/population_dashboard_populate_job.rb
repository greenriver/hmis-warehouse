module Reporting
  class PopulationDashboardPopulateJob < BaseJob

    queue_as :low_priority

    def max_attempts
      1
    end

    def perform sub_population:
      @report = Reporting::MonthlyReports::Base.class_for(sub_population.to_sym)
      raise "Unrecognized sub-population #{sub_population}" unless @report
      @report.new.populate!
    end

  end
end
