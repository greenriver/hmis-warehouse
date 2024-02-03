###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Results::TimeOnListMedian < CePerformance::Result
    include CePerformance::Results::Calculations
    # For anyone served by CE, how long have they been on the prioritization list
    def self.calculate(report, period)
      values = client_scope(report, period).pluck(:days_on_list)
      create(
        report_id: report.id,
        period: period,
        value: median(values),
        goal: report.goal_for(goal_column),
      )
    end

    def self.client_scope(report, period)
      report.clients.served_in_period(period).
        where.not(days_on_list: nil)
    end

    def self.goal_column
      :time_on_list
    end

    def self.title
      Translation.translate('Median Length of Time on Prioritization List')
    end

    def description
      "Persons in the CoC will have a median length of time on the prioritization list of **no more than #{goal} days**."
    end

    def self.calculation
      'Median number of days between CE Assessment and Exit Date, or Report Period End Date for Stayers'
    end

    def self.category
      'Time'
    end

    def self.display_result?
      false
    end

    def unit
      'days'
    end

    def goal_direction
      '<'
    end

    def brief_goal_description
      'time between assessment and exit'
    end

    def detail_link_text
      "Median: #{number_with_delimiter(value.to_i)} days"
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
