###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Results::ExitPermanent < CePerformance::Result
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
        permanent_exit_destination
    end

    def self.title
      'Permanent Housing Situation'
    end

    def self.category
      'Activity'
    end

    def self.display_result?
      false
    end

    def description
      'Count of clients exiting to an Permanent Housing Situation.'
    end

    def self.calculation
      'Count of clients exiting from CE to a Permanent Housing Situation during report period.'
    end

    def self.breakdown_title
      'Permanent Destinations'
    end

    def display_exit_breakdown?
      true
    end

    def detail_link_text
      ''
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
