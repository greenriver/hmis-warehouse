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
      when :served_on_pit_date, :first_time
        percent_changed(reporting_value, comparison_value) > goal(field)
      when :days_homeless_es_sh_th, :days_homeless_before_move_in
        reporting_value < goal(field)
      when :so_destination
        reporting_value > goal(field)
      end
    end

    def goal(field)
      # TODO: what are the goals?
      case field
      when :served_on_pit_date, :first_time
        0 # FIXME
      when :days_homeless_es_sh_th, :days_homeless_before_move_in
        365 # FIXME
      when :so_destination
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

    def count_of_homeless_clients
      field = :served_on_pit_date
      reporting_count = client_count(field, :reporting)
      comparison_count = client_count(field, :comparison)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: 'Number of Homeless People',
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
        title: 'Number of First-Time Homeless People',
        passed: passed?(field, reporting_count, comparison_count),
        direction: direction(field, reporting_count, comparison_count),
        primary_value: number_with_delimiter(reporting_count),
        primary_unit: 'clients',
        secondary_value: (reporting_count - comparison_count) / comparison_count.to_f,
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

      reporting_average = if reporting_count.positive?
        reporting_days.to_f / reporting_count
      else
        0
      end
      comparison_average = if comparison_count.positive?
        comparison_days.to_f / comparison_count
      else
        0
      end

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: 'Length of Homeless Stay (Average Days)',
        passed: passed?(field, reporting_average, nil),
        direction: direction(field, reporting_average, comparison_average),
        primary_value: number_with_delimiter(reporting_average),
        primary_unit: 'days',
        secondary_value: (reporting_average - comparison_average) / comparison_average.to_f,
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
        title: 'Length of Homeless Stay (Median Days)',
        passed: passed?(field, reporting_median, nil),
        direction: direction(field, reporting_median, comparison_median),
        primary_value: number_with_delimiter(reporting_median),
        primary_unit: 'days',
        secondary_value: (reporting_median - comparison_median) / comparison_median.to_f,
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
      reporting_average = if reporting_count.positive?
        reporting_days.to_f / reporting_count
      else
        0
      end
      comparison_average = if comparison_count.positive?
        comparison_days.to_f / comparison_count
      else
        0
      end

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: 'Time to Move-in (Average Days)',
        passed: passed?(field, reporting_average, nil),
        direction: direction(field, reporting_average, comparison_average),
        primary_value: number_with_delimiter(reporting_average),
        primary_unit: 'days',
        secondary_value: (reporting_average - comparison_average) / comparison_average.to_f,
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
        title: 'Time to Move-in (Median Days)',
        passed: passed?(field, reporting_median, nil),
        direction: direction(field, reporting_median, comparison_median),
        primary_value: number_with_delimiter(reporting_median),
        primary_unit: 'days',
        secondary_value: (reporting_median - comparison_median) / comparison_median.to_f,
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
      reporting_percent = if reporting_denominator.positive?
        ((reporting_numerator / reporting_denominator.to_f) * 100).round
      else
        0
      end

      comparison_denominator = comparison_destinations.select(&:positive?).count
      comparison_numerator = comparison_destinations.select do |d|
        d.in?(HudSpmReport::Generators::Fy2020::Base::PERMANENT_DESTINATIONS)
      end.count
      comparison_percent = if comparison_denominator.positive?
        ((comparison_numerator / comparison_denominator.to_f) * 100).round
      else
        0
      end

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: 'Number of People Exiting SO to a Positive Destination',
        passed: passed?(field, reporting_percent, nil),
        direction: direction(field, reporting_percent, comparison_percent),
        primary_value: number_with_delimiter(reporting_numerator),
        primary_unit: 'clients',
        secondary_value: reporting_numerator,
        secondary_unit: '%',
        value_label: 'Change over year',
      )
    end

    def results_for(field)
      results.find_by(field: field)
    end

    def median(values)
      return 0 unless values.any?

      values = values.map(&:to_f)
      mid = values.size / 2
      sorted = values.sort
      return sorted[mid] if values.length.odd?

      (sorted[mid] + sorted[mid - 1]) / 2
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
        # TODO: additional metrics
      ]
      PerformanceMeasurement::Result.transaction do
        PerformanceMeasurement::Result.where(report_id: id).delete_all
        PerformanceMeasurement::Result.import(results)
      end
    end
  end
end
