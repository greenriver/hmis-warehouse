###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Results::CategoryTwo < CePerformance::Result
    include CePerformance::Results::Calculations
    # Find the number of people who are not literally homeless (category 1)
    # 1. Find all clients served (CE APR Q5 B1)
    # 2. Of those count those who did not enter with Prior Living Situation (3.917.1)
    #   homeless
    #   nor
    #   LOSUnderThreshold = yes and PreviousStreetESSH = yes
    #   nor receive a homeless CLS during the report range
    def self.calculate(report, period)
      create(
        report_id: report.id,
        period: period,
        value: client_scope(report, period).count,
      )
    end

    def self.client_scope(report, period)
      report.clients.served_in_period(period).not_literally_homeless
    end

    def self.ce_apr_question
      'Question 5'
    end

    def self.title
      _('Number of Clients Who Were Not Literally Homeless')
    end

    def description
      'Count of clients enrolled in CE who did not enter from a literally homeless situation within the reporting range, and did not have a literally homeless Current Living Situation collected during the report range.'
    end

    def self.calculation
      'Count of clients enrolled in CE who did not enter with a prior living situation of literally homeless, nor who\'s length of time was under the threshold and were previously on the street or in shelter, nor who had a literally homeless Current Living Situation collected during the report range.'
    end

    def nested_results
      [
        CePerformance::Results::CategoryTwoHousehold,
      ]
    end

    def detail_link_text
      "#{value.to_i} #{unit}"
    end

    def unit
      'clients'
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
