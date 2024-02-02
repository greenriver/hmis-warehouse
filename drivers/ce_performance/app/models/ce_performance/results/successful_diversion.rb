###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Results::SuccessfulDiversion < CePerformance::Result
    include CePerformance::Results::Calculations
    # 1. Find the number of people who received a successful diversion event
    # 2. Divide those by the number of people who received a diversion event
    def self.calculate(report, period)
      diverted = diverted_scope(report, period).count
      successfully_diverted = successfully_diverted_scope(report, period).count
      create(
        report_id: report.id,
        period: period,
        value: percent_of(successfully_diverted, diverted),
        numerator: successfully_diverted,
        denominator: diverted,
        goal: report.goal_for(goal_column),
      )
    end

    def self.client_scope(report, period)
      successfully_diverted_scope(report, period)
    end

    def self.diverted_scope(report, period)
      report.clients.in_period(period).diverted
    end

    def self.successfully_diverted_scope(report, period)
      report.clients.in_period(period).successfully_diverted
    end

    def self.goal_column
      :diversion
    end

    def self.ce_apr_question
      'Question 9'
    end

    def self.category
      'Participation'
    end

    def goal_line
      nil
    end

    def max_100?
      true
    end

    def passed?(comparison)
      value.present? && percent_change_over_year(comparison) > goal
    end

    def percentage?
      true
    end

    def self.title
      Translation.translate('Number of persons successfully Diverted')
    end

    def description
      "The CoC will increase successful diversion by **#{goal}% annually**."
    end

    def unit
      'percent'
    end

    def goal_direction
      '+'
    end

    def brief_goal_description
      'annual diversions'
    end

    def self.calculation
      'The difference (as a percentage) between the number of unduplicated households served by CE and the number with a Diversion CE Event recorded where the CE Event shows "yes" for being housed/re-housed in a safe alternative as a result'
    end

    def detail_link_text(comparison)
      "#{percent_change_over_year(comparison)}% change over year"
    end

    def indicator(comparison)
      @indicator ||= OpenStruct.new(
        primary_value: value,
        primary_unit: '% successful',
        secondary_value: percent_change_over_year(comparison),
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
        ['x', report_year, comparison_year],
        [unit, value, comparison.value],
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
