###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting
  class PopulationDashboardPopulateJob < BaseJob
    include ActionView::Helpers::DateHelper

    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def max_attempts
      1
    end

    def perform(sub_population:)
      advisory_lock_name = "population_dashboard_populate_job_#{sub_population}"
      return if Reporting::MonthlyReports::Base.advisory_lock_exists?(advisory_lock_name)

      Reporting::MonthlyReports::Base.with_advisory_lock(advisory_lock_name) do
        if sub_population == 'all'
          setup_notifier('PopulationDashboardProcessor')
          Reporting::MonthlyReports::Base.available_types.keys.reverse_each do |sub_pop|
            start_time = Time.now
            send_and_log "*#{sub_pop}* starting..."
            @report = Reporting::MonthlyReports::Base.class_for(sub_pop)
            raise "Unrecognized sub-population #{sub_population}" unless @report

            @report.new.populate!
            end_time = Time.now
            send_and_log "*#{sub_pop}* completed in #{distance_of_time_in_words(start_time, end_time)}."
          end
        else
          @report = Reporting::MonthlyReports::Base.class_for(sub_population.to_sym)
          raise "Unrecognized sub-population #{sub_population}" unless @report

          @report.new.populate!
        end
      end
    end

    def send_and_log(msg)
      @notifier.ping(msg) if @send_notifications
      Rails.logger.info msg
    end
  end
end
