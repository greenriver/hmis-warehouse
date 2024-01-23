###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Results::Exit < CePerformance::Result
    include CePerformance::Results::Calculations
    def self.calculate(report, period)
      create(
        report_id: report.id,
        period: period,
        value: client_scope(report, period).count,
      )
    end

    def self.client_scope(report, period)
      report.clients.served_in_period(period).
        where.not(exit_date: nil).
        valid_exit_destination
    end

    def self.title
      'Exit Destinations'
    end

    def self.category
      'Activity'
    end

    def description
      'Count and destination of clients exiting from CE during report period.'
    end

    def self.calculation
      'Count of clients exiting from CE during report period.'
    end

    def self.breakdown_title
      'Destinations'
    end

    def display_exit_breakdown?
      true
    end

    def nested_results
      [
        CePerformance::Results::ExitHomeless,
        CePerformance::Results::ExitInstitutional,
        CePerformance::Results::ExitTemporary,
        CePerformance::Results::ExitPermanent,
        CePerformance::Results::ExitOther,
      ]
    end

    def detail_link_text
      'Destination'
    end

    def unit
      'Clients'
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
