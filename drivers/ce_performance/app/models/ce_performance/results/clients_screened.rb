###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Results::ClientsScreened < CePerformance::Result
    include CePerformance::Results::Calculations
    # For anyone served by CE, how long have they been in the project
    def self.calculate(report, period, _filter)
      numerator = client_scope(report, period).count
      denominator = report.clients.served_in_period(period).hoh.count
      create(
        report_id: report.id,
        period: period,
        value: percent_of(numerator, denominator),
      )
    end

    def self.client_scope(report, period)
      report.clients.served_in_period(period).
        hoh.
        where.not(prevention_tool_score: nil)
    end

    # TODO: move to goal configuration
    def self.goal
      100
    end

    def self.title
      _('Clients Screened for Prevention')
    end

    def self.description
      "The CoC will screen **#{goal}%** of eligible persons for prevention."
    end

    def self.calculation
      'Percentage of the Heads of Household who were screened for prevention.'
    end

    def category
      'Participation'
    end

    def self.display_result?
      true
    end

    def goal_direction
      ''
    end

    def brief_goal_description
      'percentage screened'
    end

    def unit
      'percent'
    end

    def detail_link_text
      "#{value.to_i} clients"
    end

    def indicator(comparison)
      @indicator ||= OpenStruct.new(
        primary_value: value.to_i,
        primary_unit: unit,
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
