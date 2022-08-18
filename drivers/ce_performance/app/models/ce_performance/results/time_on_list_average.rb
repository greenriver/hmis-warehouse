###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Results::TimeOnListAverage < CePerformance::Result
    include CePerformance::Results::Calculations
    # For anyone served by CE, how long have they been on the prioritization list
    def self.calculate(report, period)
      values = client_scope(report, period).pluck(:days_on_list)
      create(
        report_id: report.id,
        period: period,
        value: average(values),
      )
    end

    def self.client_scope(report, period)
      report.clients.served_in_period(period).
        where.not(days_on_list: nil)
    end

    # TODO: move to goal configuration
    def self.goal
      30
    end

    def self.title
      _('Average Length of Time on Prioritization List')
    end

    def self.description
      "Persons in the CoC will have an average length of time on the prioritization list of **no more than #{goal} days**."
    end

    def self.calculation
      'Average number of days between CE Assessment and Exit Date, or Report Period End Date for Stayers'
    end

    def category
      'Time'
    end

    def nested_header
      'Median Time'
    end

    def nested_results
      [
        CePerformance::Results::TimeOnListMedian,
      ]
    end

    def detail_link_text
      "Average: #{value.to_i} #{unit}"
    end

    def goal_direction
      '<'
    end

    def brief_goal_description
      'time between assessment and exit'
    end

    def unit
      'days'
    end

    def indicator(comparison)
      @indicator ||= OpenStruct.new(
        primary_value: value.to_i,
        primary_unit: unit,
        secondary_value: percent_change_over_year(comparison).to_i,
        secondary_unit: '%',
        value_label: 'change over year',
        passed: passed?(comparison),
        direction: direction(comparison),
      )
    end

    def data_for_chart(report, comparison)
      aprs = report.ce_aprs.order(start_date: :asc).to_a
      comparison_year = aprs.first.end_date.year
      report_year = aprs.last.end_date.year
      columns = [
        ['x', comparison_year, report_year],
        [unit, comparison.value, value],
      ]

      {
        x: 'x',
        columns: columns,
        type: 'bar',
        labels: {
          colors: 'white',
          centered: true,
        },
      }
    end
  end
end
