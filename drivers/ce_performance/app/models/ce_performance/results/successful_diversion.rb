###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Results::SuccessfulDiversion < CePerformance::Result
    include CePerformance::Results::Calculations
    # 1. Find the number of people who received a successful diversion event
    # 2. Divide those by the number of people who received a diversion event
    def self.calculate(report, period, _filter)
      diverted = diverted_scope(report, period).count
      successfully_diverted = successfully_diverted_scope(report, period).count
      create(
        report_id: report.id,
        period: period,
        value: percent_of(successfully_diverted, diverted),
        numerator: successfully_diverted,
        denominator: diverted,
      )
    end

    def self.diverted_scope(report, period)
      report.clients.in_period(period).diverted
    end

    def self.successfully_diverted_scope(report, period)
      report.clients.in_period(period).successfully_diverted
    end

    # TODO: move to goal configuration
    def self.goal
      5
    end

    def self.title
      _('Number of persons successfully Diverted')
    end

    def self.description
      "The CoC will increase successful diversion by **#{goal}% annually**."
    end

    def self.calculation
      'The difference (as a percentage) between the number of unduplicated households served by CE and the number with a Diversion CE Event recorded where the CE Event shows "yes" for being housed/re-housed in a safe alternative as a result'
    end

    def max_100?
      true
    end

    def detail_link_text
      "#{value}% change over year"
    end

    def indicator(comparison)
      @indicator ||= OpenStruct.new(
        primary_value: value,
        primary_unit: '% successful',
        secondary_value: change_over_year(comparison),
        secondary_unit: '%',
        value_label: 'change over year',
        passed: passed?,
        direction: direction(comparison),
      )
    end

    def data_for_chart(report, comparison)
      aprs = report.ce_aprs.order(start_date: :asc).to_a
      comparison_year = aprs.first.end_date.year
      report_year = aprs.last.end_date.year
      columns = [
        ['x', report_year, comparison_year],
        ['days', value, comparison.value],
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
