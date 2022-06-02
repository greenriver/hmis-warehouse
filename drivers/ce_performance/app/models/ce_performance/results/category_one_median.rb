###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Results::CategoryOneMedian < CePerformance::Result
    include CePerformance::Results::Calculations
    # Find the number of people who are literally homeless (category 1)
    # 1. Find all clients served (CE APR Q5 B1)
    # 2. Of those count those who entered with Prior Living Situation (3.917.1)
    #   homeless
    #   or
    #   LOSUnderThreshold = yes and PreviousStreetESSH yes
    def self.calculate(report, period, _filter)
      values = client_scope(report, period).pluck(:days_in_project)
      create(
        report_id: report.id,
        period: period,
        value: median(values),
      )
    end

    def self.client_scope(report, period)
      report.clients.served_in_period(period).literally_homeless_at_entry
    end

    # TODO: move to goal configuration
    def self.goal
      30
    end

    def self.title
      _('Median Length of Time in CE')
    end

    def self.description
      "Persons in the CoC will have an median length of time in CE of **no more than #{goal} days**."
    end

    def self.calculation
      'Median number of days between CE Project Start Date and Exit Date, or Report Period End Date for Stayers'
    end

    def self.display_result?
      false
    end

    def passed?
      value.present? && value < self.class.goal
    end

    def detail_link_text
      "Median: #{value} days"
    end
  end
end
