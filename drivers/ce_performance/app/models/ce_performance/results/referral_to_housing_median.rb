###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Results::ReferralToHousingMedian < CePerformance::Result
    include CePerformance::Results::Calculations
    # For anyone served by CE, how long between referral and housing
    def self.calculate(report, period, _filter)
      values = client_scope(report, period).pluck(:days_between_referral_and_housing)
      create(
        report_id: report.id,
        period: period,
        value: median(values),
      )
    end

    def self.client_scope(report, period)
      report.clients.served_in_period(period)
    end

    # TODO: move to goal configuration
    def self.goal
      5
    end

    def passed?(comparison)
      return false if value.nil?
      # we can't get any shorter
      return true if value.zero?
      # we were under the threshold last year, and we're lower now
      return true if comparison.value.present? && comparison.value <= self.class.goal && value <= comparison.value

      # change over year is better than goal
      change_over_year(comparison) <= -self.class.goal
    end

    def self.title
      _('Median Length of Time from CE Project Entry to Housing Referral')
    end

    def self.description
      "The CoC will decrease the median length of time from CE Project Entry to Housing Referral by **#{goal} days** annually."
    end

    def self.calculation
      'Median number of days between CE Project Start Date and Housing Referral Date'
    end

    def self.display_result?
      false
    end

    def detail_link_text
      "Median: #{value.to_i} days"
    end

    def indicator(comparison)
      @indicator ||= OpenStruct.new(
        primary_value: value.to_i,
        primary_unit: 'days',
        secondary_value: change_over_year(comparison).to_i,
        secondary_unit: 'days',
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
        ['days', comparison.value, value],
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
