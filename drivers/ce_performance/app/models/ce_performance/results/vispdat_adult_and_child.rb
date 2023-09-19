###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Results::VispdatAdultAndChild < CePerformance::Result
    include CePerformance::Results::Calculations
    def self.calculate(report, period)
      create(
        report_id: report.id,
        period: period,
        value: average(client_scope(report, period).pluck(:assessment_score)),
      )
    end

    def self.client_scope(report, period)
      report.clients.served_in_period(period).where.not(assessment_score: nil).where(vispdat_type: 'Family')
    end

    def self.ce_apr_question
      'Question 5'
    end

    def self.title
      Translation.translate('Average Family VI-SPDAT Score')
    end

    def self.category
      'Activity'
    end

    def description
      'Average Family VI-SPDAT score for clients enrolled during the report period.'
    end

    def self.calculation
      'The average of the most recent Family VI-SPDAT scores collected before the end of the report period for clients enrolled during the reporting period.'
    end

    def display_vispdat_breakdown?
      return false unless report.include_supplemental?

      true
    end

    def self.display_result?
      false
    end

    def detail_link_text
      'VI-SPDAT details'
    end

    def unit
      'average score'
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
