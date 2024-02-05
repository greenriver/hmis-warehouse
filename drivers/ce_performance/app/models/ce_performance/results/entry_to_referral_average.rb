###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Results::EntryToReferralAverage < CePerformance::Result
    include CePerformance::Results::Calculations
    # For anyone served by CE, how long between entry and referral
    def self.calculate(report, period)
      values = client_scope(report, period).
        pluck(:days_between_entry_and_initial_referral)
      create(
        report_id: report.id,
        period: period,
        value: average(values),
        goal: report.goal_for(goal_column),
      )
    end

    def self.client_scope(report, period)
      report.clients.served_in_period(period).
        where.not(days_between_entry_and_initial_referral: nil)
    end

    def goal_progress(comparison)
      change_over_year(comparison).to_i
    end

    def self.goal_column
      :time_to_referral
    end

    def goal_line
      nil
    end

    def passed?(comparison)
      return false if value.nil?
      # we can't get any shorter
      return true if value.zero?
      # we were under the threshold last year, and we're lower now
      return true if comparison.value.present? && comparison.value <= goal && value <= comparison.value

      # change over year is better than goal
      change_over_year(comparison) <= -goal
    end

    def self.title
      Translation.translate('Average Length of Time from CE Project Entry to Housing Referral')
    end

    def self.category
      'Time'
    end

    def description
      "The CoC will decrease the average combined length of time from CE Project Entry to Housing Referral by **#{goal} days** annually."
    end

    def self.calculation
      'Average number of days between CE Project Start Date and Housing Referral Date'
    end

    def goal_direction
      '-'
    end

    def brief_goal_description
      'time to referral'
    end

    def nested_header
      'Median Time'
    end

    def nested_results
      [
        CePerformance::Results::EntryToReferralMedian,
      ]
    end

    def detail_link_text
      "Average: #{number_with_delimiter(value.to_i)} #{unit}"
    end

    def unit
      'days'
    end

    def indicator(comparison)
      @indicator ||= OpenStruct.new(
        primary_value: value.to_i,
        primary_unit: unit,
        secondary_value: change_over_year(comparison).to_i,
        secondary_unit: unit,
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
