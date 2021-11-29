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
        percent_changed(reporting_value, comparison_value) < goal(field)
      when :days_homeless_es_sh_th, :days_homeless_es_sh_th_ph, :days_to_return
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
      when :days_homeless_es_sh_th, :days_homeless_es_sh_th_ph
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
      return 0 unless reporting_count.present? && comparison_count.present?

      ((reporting_count - comparison_count) / comparison_count.to_f) * 100
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

    def client_count(field, period, project_id: nil)
      column = "#{period}_#{field}"
      return clients.where(column => true).count if project_id.blank?

      @client_counts ||= {}
      @client_counts[column] ||= clients.joins(:client_projects).
        merge(PerformanceMeasurement::ClientProject.where.not(project_id: nil)).
        group(:project_id).
        where(column => true).distinct.count
      @client_counts[column][project_id] || 0
    end

    def client_sum(field, period, project_id: nil)
      column = "#{period}_#{field}"
      return clients.where.not(column => nil).sum(column) if project_id.blank?

      @client_sums ||= {}
      @client_sums[column] ||= clients.joins(:client_projects).
        merge(PerformanceMeasurement::ClientProject.where.not(project_id: nil)).
        group(:project_id).
        where.not(column => nil).distinct.sum(column)
      @client_sums[column][project_id] || 0
    end

    def client_data(field, period, project_id: nil)
      column = "#{period}_#{field}"
      return clients.where.not(column => nil).pluck(column) if project_id.blank?

      @client_datas ||= {}
      existing = @client_datas.dig(column)
      return existing.dig(project_id) || [] if existing.present?

      clients.
        joins(:client_projects).
        merge(PerformanceMeasurement::ClientProject.where.not(project_id: nil)).
        where.not(column => nil).distinct.pluck(:project_id, column).each do |p_id, value|
          @client_datas[column] ||= {}
          @client_datas[column][p_id] ||= []
          @client_datas[column][p_id] << value
        end
      @client_datas.dig(column, project_id) || []
    end

    def count_of_sheltered_homeless_clients(project_id: nil)
      field = :served_on_pit_date_sheltered

      reporting_count = client_count(field, :reporting, project_id: project_id)
      comparison_count = client_count(field, :comparison, project_id: project_id)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_count, comparison_count),
        direction: direction(field, reporting_count, comparison_count),
        primary_value: reporting_count,
        primary_unit: 'clients',
        secondary_value: percent_changed(reporting_count, comparison_count),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_count,
        system_level: project_id.blank?,
        project_id: project_id,
        goal: goal(field),
      )
    end

    # NOTE: SPM does not include SO, so this needs to be done based on SHS
    def count_of_homeless_clients(project_id: nil)
      field = :served_on_pit_date
      reporting_count = client_count(field, :reporting, project_id: project_id)
      comparison_count = client_count(field, :comparison, project_id: project_id)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_count, comparison_count),
        direction: direction(field, reporting_count, comparison_count),
        primary_value: reporting_count,
        primary_unit: 'clients',
        secondary_value: percent_changed(reporting_count, comparison_count),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_count,
        system_level: project_id.blank?,
        project_id: project_id,
        goal: goal(field),
      )
    end

    # NOTE: SPM does not include SO, so this needs to be done based on SHS
    def count_of_unsheltered_homeless_clients(project_id: nil)
      field = :served_on_pit_date_unsheltered
      reporting_count = client_count(field, :reporting, project_id: project_id)
      comparison_count = client_count(field, :comparison, project_id: project_id)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_count, comparison_count),
        direction: direction(field, reporting_count, comparison_count),
        primary_value: reporting_count,
        primary_unit: 'clients',
        secondary_value: percent_changed(reporting_count, comparison_count),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_count,
        system_level: project_id.blank?,
        project_id: project_id,
        goal: goal(field),
      )
    end

    def first_time_homeless_clients(project_id: nil)
      field = :first_time
      reporting_count = client_count(field, :reporting, project_id: project_id)
      comparison_count = client_count(field, :comparison, project_id: project_id)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_count, comparison_count),
        direction: direction(field, reporting_count, comparison_count),
        primary_value: reporting_count,
        primary_unit: 'clients',
        secondary_value: percent_of(reporting_count - comparison_count, comparison_count),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_count,
        system_level: project_id.blank?,
        project_id: project_id,
        goal: goal(field),
      )
    end

    def length_of_homeless_stay_average(project_id: nil)
      field = :days_homeless_es_sh_th
      reporting_count = client_count(field, :reporting, project_id: project_id)
      comparison_count = client_count(field, :comparison, project_id: project_id)
      reporting_days = client_sum(field, :reporting, project_id: project_id)
      comparison_days = client_sum(field, :comparison, project_id: project_id)

      reporting_average = average(reporting_days, reporting_count)
      comparison_average = average(comparison_days, comparison_count)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_average, nil),
        direction: direction(field, reporting_average, comparison_average),
        primary_value: reporting_average,
        primary_unit: 'days',
        secondary_value: percent_of(reporting_average - comparison_average, comparison_average),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_average,
        system_level: project_id.blank?,
        project_id: project_id,
        goal: goal(field),
      )
    end

    def length_of_homeless_stay_median(project_id: nil)
      field = :days_homeless_es_sh_th
      reporting_days = client_data(field, :reporting, project_id: project_id)
      comparison_days = client_data(field, :comparison, project_id: project_id)

      reporting_median = median(reporting_days)
      comparison_median = median(comparison_days)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_median, nil),
        direction: direction(field, reporting_median, comparison_median),
        primary_value: reporting_median,
        primary_unit: 'days',
        secondary_value: percent_of(reporting_median - comparison_median, comparison_median),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_median,
        system_level: project_id.blank?,
        project_id: project_id,
        goal: goal(field),
      )
    end

    def time_to_move_in_average(project_id: nil)
      field = :days_homeless_es_sh_th_ph
      reporting_count = client_count(field, :reporting, project_id: project_id)
      comparison_count = client_count(field, :comparison, project_id: project_id)
      reporting_days = client_sum(field, :reporting, project_id: project_id)
      comparison_days = client_sum(field, :comparison, project_id: project_id)
      reporting_average = average(reporting_days, reporting_count)
      comparison_average = average(comparison_days, comparison_count)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_average, nil),
        direction: direction(field, reporting_average, comparison_average),
        primary_value: reporting_average,
        primary_unit: 'days',
        secondary_value: percent_of(reporting_average - comparison_average, comparison_average),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_average,
        system_level: project_id.blank?,
        project_id: project_id,
        goal: goal(field),
      )
    end

    def time_to_move_in_median(project_id: nil)
      field = :days_homeless_es_sh_th_ph
      reporting_days = client_data(field, :reporting, project_id: project_id)
      comparison_days = client_data(field, :comparison, project_id: project_id)

      reporting_median = median(reporting_days)
      comparison_median = median(comparison_days)

      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        passed: passed?(field, reporting_median, nil),
        direction: direction(field, reporting_median, comparison_median),
        primary_value: reporting_median,
        primary_unit: 'days',
        secondary_value: percent_of(reporting_median - comparison_median, comparison_median),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_median,
        system_level: project_id.blank?,
        project_id: project_id,
        goal: goal(field),
      )
    end

    def so_positive_destinations(project_id: nil)
      field = :so_destination
      reporting_destinations = client_data(field, :reporting, project_id: project_id)
      comparison_destinations = client_data(field, :comparison, project_id: project_id)
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
        primary_value: reporting_numerator,
        primary_unit: 'clients',
        secondary_value: reporting_percent,
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_numerator,
        system_level: project_id.blank?,
        project_id: project_id,
        goal: goal(field),
      )
    end

    def es_sh_th_rrh_positive_destinations(project_id: nil)
      field = :es_sh_th_rrh_destination
      reporting_destinations = client_data(field, :reporting, project_id: project_id)
      comparison_destinations = client_data(field, :comparison, project_id: project_id)
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
        primary_value: reporting_numerator,
        primary_unit: 'clients',
        secondary_value: reporting_percent,
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_numerator,
        system_level: project_id.blank?,
        project_id: project_id,
        goal: goal(field),
      )
    end

    def moved_in_positive_destinations(project_id: nil)
      field = :moved_in_destination
      reporting_destinations = client_data(field, :reporting, project_id: project_id)
      comparison_destinations = client_data(field, :comparison, project_id: project_id)
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
        primary_value: reporting_numerator,
        primary_unit: 'clients',
        secondary_value: reporting_percent,
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_numerator,
        system_level: project_id.blank?,
        project_id: project_id,
        goal: goal(field),
      )
    end

    def returned_in_six_months(project_id: nil)
      returned_in_range(1..180, __method__, project_id: project_id)
    end

    def returned_in_twenty_two_years(project_id: nil)
      returned_in_range(1..180, __method__, project_id: project_id)
    end

    def returned_in_range(range, meth, project_id: nil)
      field = :days_to_return
      reporting_returns = client_data(field, :reporting, project_id: project_id)
      comparison_returns = client_data(field, :comparison, project_id: project_id)
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
        primary_value: reporting_numerator,
        primary_unit: 'clients',
        secondary_value: reporting_percent,
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_numerator,
        system_level: project_id.blank?,
        project_id: project_id,
        goal: goal(field),
      )
    end

    def stayers_with_increased_income(project_id: nil)
      increased_income(:increased_income, :income_stayer, __method__, project_id: project_id)
    end

    def leavers_with_increased_income(project_id: nil)
      increased_income(:increased_income, :income_leaver, __method__, project_id: project_id)
    end

    def increased_income(income_field, status_field, meth, project_id: nil)
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
        primary_value: reporting_numerator,
        primary_unit: 'clients',
        secondary_value: reporting_percent,
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_numerator,
        system_level: project_id.blank?,
        project_id: project_id,
      )
    end

    def result_for(field, project_id: nil)
      return results.find_by(field: field, system_level: true) if project_id.blank?

      results.find_by(field: field, project_id: project_id)
    end

    def save_results
      results = result_methods.map { |method| send(method) }
      projects.each do |project|
        result_methods.each do |method|
          results << send(method, project_id: project.project_id)
        end
      end
      PerformanceMeasurement::Result.transaction do
        PerformanceMeasurement::Result.where(report_id: id).delete_all
        PerformanceMeasurement::Result.import!(results, batch_size: 5_000)
      end
    end

    private def result_methods
      [
        :count_of_sheltered_homeless_clients,
        :count_of_homeless_clients,
        :count_of_unsheltered_homeless_clients,
        :first_time_homeless_clients,
        :length_of_homeless_stay_average,
        :length_of_homeless_stay_median,
        :time_to_move_in_average,
        :time_to_move_in_median,
        :so_positive_destinations,
        :es_sh_th_rrh_positive_destinations,
        :moved_in_positive_destinations,
        :returned_in_six_months,
        :returned_in_twenty_two_years,
        :stayers_with_increased_income,
        :leavers_with_increased_income,
      ]
    end
  end
end
