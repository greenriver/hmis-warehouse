###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Results::CategoryOneHousehold < CePerformance::Result
    include CePerformance::Results::Calculations
    # Find the number of people who are literally homeless (category 1)
    # 1. Find all clients served (CE APR Q5 B1)
    # 2. Of those count those who entered with Prior Living Situation (3.917.1)
    #   homeless
    #   or
    #   LOSUnderThreshold = yes and PreviousStreetESSH yes
    def self.calculate(report, period, _filter)
      create(
        report_id: report.id,
        period: period,
        value: client_scope(report, period).count,
      )
    end

    def self.client_scope(report, period)
      report.clients.served_in_period(period).literally_homeless_at_entry.where(head_of_household: true)
    end

    # TODO: move to goal configuration
    def self.goal
      nil
    end

    def self.ce_apr_question
      'Question 5'
    end

    def self.title
      _('Number of Households in Category 1')
    end

    def self.description
      'Count of heads of households enrolled in CE who entered from Category 1 homelessness within the reporting range.'
    end

    def self.calculation
      'Count of heads of households enrolled in CE who entered with a prior living situation of literally homeless, or who\'s length of time was under the threshold and were previously on the street or in shelter.'
    end

    def self.display_result?
      false
    end

    def display_goal?
      false
    end

    def detail_link_text
      "#{value.to_i} #{unit}"
    end

    def unit
      'households'
    end

    def max_100?
      true
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
