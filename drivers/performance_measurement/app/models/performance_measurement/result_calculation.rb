###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement::ResultCalculation
  extend ActiveSupport::Concern

  included do
    def passed?(field, reporting_value, comparison_value)
      case field
      when :served_on_pit_date, :first_time, :served_on_pit_date_sheltered, :served_on_pit_date_unsheltered
        percent_changed(reporting_value, comparison_value) > goal(field)
      when :days_homeless_es_sh_th, :days_homeless_before_move_in, :days_to_return
        reporting_value < goal(field)
      when :so_destination, :es_sh_th_rrh_destination, :moved_in_destination, :increased_income
        reporting_value > goal(field)
      end
    end

    def goal(field)
      # TODO: what are the goals?
      case field
      when :served_on_pit_date, :first_time, :served_on_pit_date_sheltered, :served_on_pit_date_unsheltered
        0 # FIXME
      when :days_homeless_es_sh_th, :days_homeless_before_move_in
        365 # FIXME
      when :so_destination, :es_sh_th_rrh_destination, :moved_in_destination, :days_to_return, :increased_income
        0 # FIXME (percent change)
      else
        1 # FIXME
      end
    end

    def direction(field, reporting_value, comparison_value)
      if reporting_value == comparison_value
        :none
      elsif passed?(field, reporting_value, comparison_value)
        :down
      else
        :up
      end
    end

    def percent_changed(reporting_count, comparison_count)
      (reporting_count - comparison_count) / comparison_count.to_f
    end

    def percent_of(numerator, denominator)
      return 0 unless denominator.positive?

      ((numerator / denominator.to_f) * 100).round
    end

    def average(value, count)
      return 0 unless count.positive?

      value.to_f / count
    end

    def median(values)
      return 0 unless values.any?

      values = values.map(&:to_f)
      mid = values.size / 2
      sorted = values.sort
      return sorted[mid] if values.length.odd?

      (sorted[mid] + sorted[mid - 1]) / 2
    end

    def client_count(field, period)
      column = "#{period}_#{field}"
      clients.where(column => true).count
    end

    def client_sum(field, period)
      column = "#{period}_#{field}"
      clients.where.not(column => nil).sum(column)
    end

    def client_data(field, period)
      column = "#{period}_#{field}"
      clients.where.not(column => nil).pluck(column)
    end

    def count_of_sheltered_homeless_clients
      field = :served_on_pit_date_sheltered
      reporting_count = client_count(field, :reporting)
      comparison_count = client_count(field, :comparison)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_count, comparison_count),
        direction: direction(field, reporting_count, comparison_count),
        primary_value: number_with_delimiter(reporting_count),
        primary_unit: 'clients',
        secondary_value: percent_changed(reporting_count, comparison_count),
        secondary_unit: '%',
        value_label: 'Change over year',
      )
    end

    # NOTE: SPM does not include SO, so this needs to be done based on SHS
    def count_of_homeless_clients
      field = :served_on_pit_date
      reporting_count = client_count(field, :reporting)
      comparison_count = client_count(field, :comparison)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_count, comparison_count),
        direction: direction(field, reporting_count, comparison_count),
        primary_value: number_with_delimiter(reporting_count),
        primary_unit: 'clients',
        secondary_value: percent_changed(reporting_count, comparison_count),
        secondary_unit: '%',
        value_label: 'Change over year',
      )
    end

    # NOTE: SPM does not include SO, so this needs to be done based on SHS
    def count_of_unsheltered_homeless_clients
      field = :served_on_pit_date_unsheltered
      reporting_count = client_count(field, :reporting)
      comparison_count = client_count(field, :comparison)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_count, comparison_count),
        direction: direction(field, reporting_count, comparison_count),
        primary_value: number_with_delimiter(reporting_count),
        primary_unit: 'clients',
        secondary_value: percent_changed(reporting_count, comparison_count),
        secondary_unit: '%',
        value_label: 'Change over year',
      )
    end

    def first_time_homeless_clients
      field = :first_time
      reporting_count = client_count(field, :reporting)
      comparison_count = client_count(field, :comparison)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_count, comparison_count),
        direction: direction(field, reporting_count, comparison_count),
        primary_value: number_with_delimiter(reporting_count),
        primary_unit: 'clients',
        secondary_value: percent_of(reporting_count - comparison_count, comparison_count),
        secondary_unit: '%',
        value_label: 'Change over year',
      )
    end

    def length_of_homeless_stay_average
      field = :days_homeless_es_sh_th
      reporting_count = client_count(field, :reporting)
      comparison_count = client_count(field, :comparison)
      reporting_days = client_sum(field, :reporting)
      comparison_days = client_sum(field, :comparison)

      reporting_average = average(reporting_days, reporting_count)
      comparison_average = average(comparison_days, comparison_count)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_average, nil),
        direction: direction(field, reporting_average, comparison_average),
        primary_value: number_with_delimiter(reporting_average),
        primary_unit: 'days',
        secondary_value: percent_of(reporting_average - comparison_average, comparison_average),
        secondary_unit: '%',
        value_label: 'Change over year',
      )
    end

    def length_of_homeless_stay_median
      field = :days_homeless_es_sh_th
      reporting_days = client_data(field, :reporting)
      comparison_days = client_data(field, :comparison)

      reporting_median = median(reporting_days)
      comparison_median = median(comparison_days)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_median, nil),
        direction: direction(field, reporting_median, comparison_median),
        primary_value: number_with_delimiter(reporting_median),
        primary_unit: 'days',
        secondary_value: percent_of(reporting_median - comparison_median, comparison_median),
        secondary_unit: '%',
        value_label: 'Change over year',
      )
    end

    def time_to_move_in_average
      field = :days_homeless_before_move_in
      reporting_count = client_count(field, :reporting)
      comparison_count = client_count(field, :comparison)
      reporting_days = client_sum(field, :reporting)
      comparison_days = client_sum(field, :comparison)
      reporting_average = average(reporting_days, reporting_count)
      comparison_average = average(comparison_days, comparison_count)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_average, nil),
        direction: direction(field, reporting_average, comparison_average),
        primary_value: number_with_delimiter(reporting_average),
        primary_unit: 'days',
        secondary_value: percent_of(reporting_average - comparison_average, comparison_average),
        secondary_unit: '%',
        value_label: 'Change over year',
      )
    end

    def time_to_move_in_median
      field = :days_homeless_before_move_in
      reporting_days = client_data(field, :reporting)
      comparison_days = client_data(field, :comparison)

      reporting_median = median(reporting_days)
      comparison_median = median(comparison_days)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_median, nil),
        direction: direction(field, reporting_median, comparison_median),
        primary_value: number_with_delimiter(reporting_median),
        primary_unit: 'days',
        secondary_value: percent_of(reporting_median - comparison_median, comparison_median),
        secondary_unit: '%',
        value_label: 'Change over year',
      )
    end

    def so_positive_destinations
      field = :so_destination
      reporting_destinations = client_data(field, :reporting)
      comparison_destinations = client_data(field, :comparison)
      reporting_denominator = reporting_destinations.select(&:positive?).count
      reporting_numerator = reporting_destinations.select do |d|
        d.in?(HudSpmReport::Generators::Fy2020::Base::PERMANENT_DESTINATIONS)
      end.count
      reporting_percent = percent_of(reporting_numerator, reporting_denominator)

      comparison_denominator = comparison_destinations.select(&:positive?).count
      comparison_numerator = comparison_destinations.select do |d|
        d.in?(HudSpmReport::Generators::Fy2020::Base::PERMANENT_DESTINATIONS)
      end.count
      comparison_percent = percent_of(comparison_numerator, comparison_denominator)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_percent, nil),
        direction: direction(field, reporting_percent, comparison_percent),
        primary_value: number_with_delimiter(reporting_numerator),
        primary_unit: 'clients',
        secondary_value: reporting_percent,
        secondary_unit: '%',
        value_label: 'Change over year',
      )
    end

    def es_sh_th_rrh_positive_destinations
      field = :es_sh_th_rrh_destination
      reporting_destinations = client_data(field, :reporting)
      comparison_destinations = client_data(field, :comparison)
      reporting_denominator = reporting_destinations.select(&:positive?).count
      reporting_numerator = reporting_destinations.select do |d|
        d.in?(HudSpmReport::Generators::Fy2020::Base::PERMANENT_DESTINATIONS)
      end.count
      reporting_percent = percent_of(reporting_numerator, reporting_denominator)

      comparison_denominator = comparison_destinations.select(&:positive?).count
      comparison_numerator = comparison_destinations.select do |d|
        d.in?(HudSpmReport::Generators::Fy2020::Base::PERMANENT_DESTINATIONS)
      end.count
      comparison_percent = percent_of(comparison_numerator, comparison_denominator)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_percent, nil),
        direction: direction(field, reporting_percent, comparison_percent),
        primary_value: number_with_delimiter(reporting_numerator),
        primary_unit: 'clients',
        secondary_value: reporting_percent,
        secondary_unit: '%',
        value_label: 'Change over year',
      )
    end

    def moved_in_positive_destinations
      field = :moved_in_destination
      reporting_destinations = client_data(field, :reporting)
      comparison_destinations = client_data(field, :comparison)
      reporting_denominator = reporting_destinations.select(&:positive?).count
      reporting_numerator = reporting_destinations.select do |d|
        d.in?(HudSpmReport::Generators::Fy2020::Base::PERMANENT_DESTINATIONS_OR_STAYER)
      end.count
      reporting_percent = percent_of(reporting_numerator, reporting_denominator)

      comparison_denominator = comparison_destinations.select(&:positive?).count
      comparison_numerator = comparison_destinations.select do |d|
        d.in?(HudSpmReport::Generators::Fy2020::Base::PERMANENT_DESTINATIONS_OR_STAYER)
      end.count
      comparison_percent = percent_of(comparison_numerator, comparison_denominator)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_percent, nil),
        direction: direction(field, reporting_percent, comparison_percent),
        primary_value: number_with_delimiter(reporting_numerator),
        primary_unit: 'clients',
        secondary_value: reporting_percent,
        secondary_unit: '%',
        value_label: 'Change over year',
      )
    end

    def returned_in_six_months
      returned_in_range(1..180, 'Six Months', __method__)
    end

    def returned_in_twenty_two_years
      returned_in_range(1..180, 'Two Years', __method__)
    end

    def returned_in_range(range, _descriptor, meth)
      field = :days_to_return
      reporting_returns = client_data(field, :reporting)
      comparison_returns = client_data(field, :comparison)
      reporting_denominator = reporting_returns.select(&:positive?).count
      reporting_numerator = reporting_returns.select do |d|
        d.between?(range.first, range.last)
      end.count
      reporting_percent = percent_of(reporting_numerator, reporting_denominator)

      comparison_denominator = comparison_returns.select(&:positive?).count
      comparison_numerator = comparison_returns.select do |d|
        d.between?(range.first, range.last)
      end.count
      comparison_percent = percent_of(comparison_numerator, comparison_denominator)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: meth,
        title: detail_title_for(meth.to_sym),
        passed: passed?(field, reporting_percent, nil),
        direction: direction(field, reporting_percent, comparison_percent),
        primary_value: number_with_delimiter(reporting_numerator),
        primary_unit: 'clients',
        secondary_value: reporting_percent,
        secondary_unit: '%',
        value_label: 'Change over year',
      )
    end

    def stayers_with_increased_income
      increased_income(:increased_income, :income_stayer, 'Stayer', __method__)
    end

    def leavers_with_increased_income
      increased_income(:increased_income, :income_leaver, 'Leaver', __method__)
    end

    def increased_income(income_field, status_field, _status, meth)
      reporting_denominator = client_count(status_field, :reporting)
      comparison_denominator = client_count(status_field, :comparison)
      reporting_numerator = client_count(income_field, :reporting)
      comparison_numerator = client_count(income_field, :comparison)

      reporting_percent = percent_of(reporting_numerator, reporting_denominator)
      comparison_percent = percent_of(comparison_numerator, comparison_denominator)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: meth,
        title: detail_title_for(meth.to_sym),
        passed: passed?(income_field, reporting_percent, comparison_percent),
        direction: direction(income_field, reporting_percent, comparison_percent),
        primary_value: number_with_delimiter(reporting_numerator),
        primary_unit: 'clients',
        secondary_value: reporting_percent,
        secondary_unit: '%',
        value_label: 'Change over year',
      )
    end

    def results_for(field)
      results.find_by(field: field)
    end

    def save_results
      results = [
        count_of_homeless_clients,
        first_time_homeless_clients,
        length_of_homeless_stay_average,
        length_of_homeless_stay_median,
        time_to_move_in_average,
        time_to_move_in_median,
        so_positive_destinations,
        es_sh_th_rrh_positive_destinations,
        moved_in_positive_destinations,
        returned_in_six_months,
        returned_in_twenty_two_years,
        stayers_with_increased_income,
        leavers_with_increased_income,
        # TODO: additional metrics
      ]
      PerformanceMeasurement::Result.transaction do
        PerformanceMeasurement::Result.where(report_id: id).delete_all
        PerformanceMeasurement::Result.import(results)
      end
    end
  end
end
