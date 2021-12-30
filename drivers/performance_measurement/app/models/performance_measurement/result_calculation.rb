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
      when :served_on_pit_date,
        :first_time,
        :served_on_pit_date_sheltered,
        :served_on_pit_date_unsheltered
        percent_changed(reporting_value, comparison_value) < goal(field)
      when :days_homeless_es_sh_th,
        :days_homeless_es_sh_th_ph,
        :days_to_return,
        :returned_in_six_months,
        :returned_in_two_years,
        :days_in_homeless_bed_details,
        :days_in_homeless_bed,
        :days_in_homeless_bed_in_period,
        :days_in_homeless_bed_details_in_period
        reporting_value < goal(field)
      when :so_destination,
        :so_destination_positive,
        :es_sh_th_rrh_destination,
        :es_sh_th_rrh_destination_positive,
        :moved_in_destination,
        :moved_in_destination_positive,
        :increased_income,
        :increased_income__income_stayer,
        :increased_income__income_leaver
        reporting_value > goal(field)
      else
        raise "#{field} is undefined for passed?"
      end
    end

    def goal(field)
      # TODO: what are the goals?
      case field
      when :served_on_pit_date,
        :first_time,
        :served_on_pit_date_sheltered,
        :served_on_pit_date_unsheltered
        0 # FIXME
      when :days_homeless_es_sh_th,
        :days_homeless_es_sh_th_ph
        365 # FIXME
      when :so_destination,
        :so_destination_positive,
        :es_sh_th_rrh_destination,
        :es_sh_th_rrh_destination_positive,
        :moved_in_destination,
        :moved_in_destination_positive,
        :days_to_return,
        :returned_in_six_months,
        :returned_in_two_years,
        :increased_income,
        :increased_income__income_stayer,
        :increased_income__income_leaver,
        :days_in_homeless_bed_details,
        :days_in_homeless_bed,
        :days_in_homeless_bed_in_period,
        :days_in_homeless_bed_details_in_period
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
      return clients.joins(:client_projects).merge(PerformanceMeasurement::ClientProject.where(period: period, for_question: field)).count if project_id.blank?

      @client_counts ||= {}
      @client_counts[[field, period]] ||= clients.joins(:client_projects).
        merge(PerformanceMeasurement::ClientProject.where(period: period, for_question: field).where.not(project_id: nil)).
        group(:project_id).
        distinct.count
      @client_counts[[field, period]][project_id] || 0
    end

    def client_count_present(field, period, project_id: nil)
      column = "#{period}_#{field}"
      return clients.joins(:client_projects).merge(PerformanceMeasurement::ClientProject.where(period: period, for_question: field)).count if project_id.blank?

      @client_count_present ||= {}
      @client_count_present[column] ||= clients.joins(:client_projects).
        merge(PerformanceMeasurement::ClientProject.where(period: period, for_question: field).where.not(project_id: nil)).
        group(:project_id).
        distinct.count
      @client_count_present[column][project_id] || 0
    end

    def client_sum(field, period, project_id: nil)
      column = "#{period}_#{field}"
      return clients.joins(:client_projects).merge(PerformanceMeasurement::ClientProject.where(period: period, for_question: field)).sum(column) if project_id.blank?

      @client_sums ||= {}
      @client_sums[column] ||= clients.joins(:client_projects).
        merge(PerformanceMeasurement::ClientProject.where(period: period, for_question: field).where.not(project_id: nil)).
        group(:project_id).
        distinct.sum(column)
      @client_sums[column][project_id] || 0
    end

    def client_ids(field, period, project_id: nil)
      key = [period, field]
      return clients.joins(:client_projects).merge(PerformanceMeasurement::ClientProject.where(period: period, for_question: field)).pluck(:id) if project_id.blank?

      @client_ids ||= {}
      existing = @client_ids.dig(key)
      return existing.dig(project_id) || [] if existing.present?

      clients.joins(:client_projects).
        merge(PerformanceMeasurement::ClientProject.where(period: period, for_question: field).where.not(project_id: nil)).
        distinct.pluck(:project_id, :id).each do |p_id, value|
          @client_ids[key] ||= {}
          @client_ids[key][p_id] ||= []
          @client_ids[key][p_id] << value
        end
      @client_ids.dig(key, project_id) || []
    end

    def client_data(field, period, project_id: nil)
      key = [period, field]
      column = key.join('_')
      return clients.joins(:client_projects).merge(PerformanceMeasurement::ClientProject.where(period: period, for_question: field)).pluck(column) if project_id.blank?

      @client_data ||= {}
      existing = @client_data.dig(key)
      return existing.dig(project_id) || [] if existing.present?

      clients.joins(:client_projects).
        merge(PerformanceMeasurement::ClientProject.where(period: period, for_question: field).where.not(project_id: nil)).
        distinct.pluck(:project_id, column).each do |p_id, value|
          @client_data[key] ||= {}
          @client_data[key][p_id] ||= []
          @client_data[key][p_id] << value
        end
      @client_data.dig(key, project_id) || []
    end

    def count_of_sheltered_homeless_clients(field, project: nil)
      reporting_count = client_count(field, :reporting, project_id: project&.project_id)
      comparison_count = client_count(field, :comparison, project_id: project&.project_id)

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
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        goal: goal(field),
      )
    end

    # NOTE: SPM does not include SO, so this needs to be done based on SHS
    def count_of_homeless_clients(field, project: nil)
      return unless project.blank? || project.hud_project&.es? || project.hud_project&.sh? || project.hud_project&.th?

      reporting_count = client_count(field, :reporting, project_id: project&.project_id)
      comparison_count = client_count(field, :comparison, project_id: project&.project_id)

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
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        goal: goal(field),
      )
    end

    # NOTE: SPM does not include SO, so this needs to be done based on SHS
    def count_of_unsheltered_homeless_clients(field, project: nil)
      return unless project.blank? || project.hud_project&.so?

      reporting_count = client_count(field, :reporting, project_id: project&.project_id)
      comparison_count = client_count(field, :comparison, project_id: project&.project_id)

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
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        goal: goal(field),
      )
    end

    def first_time_homeless_clients(field, project: nil)
      reporting_count = client_count(field, :reporting, project_id: project&.project_id)
      comparison_count = client_count(field, :comparison, project_id: project&.project_id)

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
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        goal: goal(field),
      )
    end

    def length_of_homeless_time_homeless_average(field, project: nil)
      return unless project.blank? || project.hud_project&.es? || project.hud_project&.sh? || project.hud_project&.th?

      reporting_count = client_count_present(field, :reporting, project_id: project&.project_id)
      comparison_count = client_count_present(field, :comparison, project_id: project&.project_id)
      reporting_days = client_sum(field, :reporting, project_id: project&.project_id)
      comparison_days = client_sum(field, :comparison, project_id: project&.project_id)
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
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        goal: goal(field),
      )
    end

    def length_of_homeless_time_homeless_median(field, project: nil)
      return unless project.blank? || project.hud_project&.es? || project.hud_project&.sh? || project.hud_project&.th?

      reporting_days = client_data(field, :reporting, project_id: project&.project_id)
      comparison_days = client_data(field, :comparison, project_id: project&.project_id)

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
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        goal: goal(field),
      )
    end

    def length_of_homeless_stay_average(field, project: nil)
      return unless project.blank? || project.hud_project&.es? || project.hud_project&.sh? || project.hud_project&.th?

      reporting_count = client_count_present(field, :reporting, project_id: project&.project_id)
      comparison_count = client_count_present(field, :comparison, project_id: project&.project_id)
      reporting_days = client_sum(field, :reporting, project_id: project&.project_id)
      comparison_days = client_sum(field, :comparison, project_id: project&.project_id)
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
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        goal: goal(field),
      )
    end

    def length_of_homeless_stay_median(field, project: nil)
      return unless project.blank? || project.hud_project&.es? || project.hud_project&.sh? || project.hud_project&.th?

      reporting_days = client_data(field, :reporting, project_id: project&.project_id)
      comparison_days = client_data(field, :comparison, project_id: project&.project_id)

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
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        goal: goal(field),
      )
    end

    def time_to_move_in_average(field, project: nil)
      return unless project.blank? || project.hud_project&.es? || project.hud_project&.sh? || project.hud_project&.th? || project.hud_project&.ph?

      reporting_count = client_count_present(field, :reporting, project_id: project&.project_id)
      comparison_count = client_count_present(field, :comparison, project_id: project&.project_id)
      reporting_days = client_sum(field, :reporting, project_id: project&.project_id)
      comparison_days = client_sum(field, :comparison, project_id: project&.project_id)
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
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        goal: goal(field),
      )
    end

    def time_to_move_in_median(field, project: nil)
      return unless project.blank? || project.hud_project&.es? || project.hud_project&.sh? || project.hud_project&.th? || project.hud_project&.ph?

      reporting_days = client_data(field, :reporting, project_id: project&.project_id)
      comparison_days = client_data(field, :comparison, project_id: project&.project_id)

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
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        goal: goal(field),
      )
    end

    def so_positive_destinations(field, project: nil)
      return unless project.blank? || project.hud_project&.so?

      reporting_destinations = client_ids(:so_destination, :reporting, project_id: project&.project_id)
      reporting_destinations_in_range = client_ids(field, :reporting, project_id: project&.project_id)
      comparison_destinations = client_ids(:so_destination, :comparison, project_id: project&.project_id)
      comparison_destinations_in_range = client_ids(field, :comparison, project_id: project&.project_id)
      reporting_denominator = reporting_destinations.count
      reporting_numerator = reporting_destinations_in_range.count
      reporting_percent = percent_of(reporting_numerator, reporting_denominator)

      comparison_denominator = comparison_destinations.count
      comparison_numerator = comparison_destinations_in_range.count
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
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        goal: goal(field),
      )
    end

    def es_sh_th_rrh_positive_destinations(field, project: nil)
      reporting_destinations = client_ids(:es_sh_th_rrh_destination, :reporting, project_id: project&.project_id)
      reporting_destinations_in_range = client_ids(field, :reporting, project_id: project&.project_id)
      comparison_destinations = client_ids(:es_sh_th_rrh_destination, :comparison, project_id: project&.project_id)
      comparison_destinations_in_range = client_ids(field, :comparison, project_id: project&.project_id)
      reporting_denominator = reporting_destinations.count
      reporting_numerator = reporting_destinations_in_range.count
      reporting_percent = percent_of(reporting_numerator, reporting_denominator)

      comparison_denominator = comparison_destinations.count
      comparison_numerator = comparison_destinations_in_range.count
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
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        goal: goal(field),
      )
    end

    def moved_in_positive_destinations(field, project: nil)
      reporting_destinations = client_ids(:moved_in_destination, :reporting, project_id: project&.project_id)
      reporting_destinations_in_range = client_ids(field, :reporting, project_id: project&.project_id)
      comparison_destinations = client_ids(:moved_in_destination, :comparison, project_id: project&.project_id)
      comparison_destinations_in_range = client_ids(field, :comparison, project_id: project&.project_id)
      reporting_denominator = reporting_destinations.count
      reporting_numerator = reporting_destinations_in_range.count
      reporting_percent = percent_of(reporting_numerator, reporting_denominator)

      comparison_denominator = comparison_destinations.count
      comparison_numerator = comparison_destinations_in_range.count
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
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        goal: goal(field),
      )
    end

    def returned_in_six_months(field, project: nil)
      returned_in_range(field, __method__, project: project)
    end

    def returned_in_two_years(field, project: nil)
      returned_in_range(field, __method__, project: project)
    end

    def returned_in_range(field, meth, project: nil)
      reporting_returns = client_ids(:returned_ever, :reporting, project_id: project&.project_id)
      reporting_returns_in_range = client_ids(field, :reporting, project_id: project&.project_id)
      comparison_returns = client_ids(:returned_ever, :comparison, project_id: project&.project_id)
      comparison_returns_in_range = client_ids(field, :comparison, project_id: project&.project_id)
      reporting_denominator = reporting_returns.count
      reporting_numerator = reporting_returns_in_range.count
      reporting_percent = percent_of(reporting_numerator, reporting_denominator)

      comparison_denominator = comparison_returns.count
      comparison_numerator = comparison_returns_in_range.count
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
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        goal: goal(field),
      )
    end

    # def es_average_bed_utilization(project: nil)
    #   if project&.project_id.blank?
    #     average_bed_utilization(:es, __method__)
    #   else
    #     average_bed_utilization_for_project(:es, __method__, project: project)
    #   end
    # end

    # def average_bed_utilization_for_project(project_type, meth, project:)
    #   field = "days_in_#{project_type}_bed_details_in_period"
    #   reporting_days = client_ids(field, :reporting, project_id: project.id)
    #   comparison_days = client_ids(field, :comparison, project_id: project.id)
    #   reporting_denominator = reporting_days
    #   reporting_numerator = reporting_days.map do |days|
    #     if days[project_id].
    #   end
    # end

    # def average_bed_utilization(project_type, meth)
    #   field = "days_in_#{project_type}_bed_in_period"
    #   reporting_days = client_ids(field, :reporting)
    #   comparison_days = client_ids(field, :comparison)
    #   reporting_denominator = reporting_returns.select(&:positive?).count
    #   reporting_numerator = reporting_returns.select do |d|
    #     d.between?(range.first, range.last)
    #   end.count
    #   reporting_percent = percent_of(reporting_numerator, reporting_denominator)

    #   comparison_denominator = comparison_returns.select(&:positive?).count
    #   comparison_numerator = comparison_returns.select do |d|
    #     d.between?(range.first, range.last)
    #   end.count
    #   comparison_percent = percent_of(comparison_numerator, comparison_denominator)

    #   PerformanceMeasurement::Result.new(
    #     report_id: id,
    #     field: meth,
    #     title: detail_title_for(meth.to_sym),
    #     passed: passed?(field, reporting_percent, nil),
    #     direction: direction(field, reporting_percent, comparison_percent),
    #     primary_value: reporting_numerator,
    #     primary_unit: 'clients',
    #     secondary_value: reporting_percent,
    #     secondary_unit: '%',
    #     value_label: 'Change over year',
    #     comparison_primary_value: comparison_numerator,
    #     system_level: project&.project_id.blank?,
    #     project_id: project&.project_id,
    #     goal: goal(field),
    #   )
    # end

    def stayers_with_increased_income(field, project: nil)
      increased_income(field, :income_stayer, __method__, project: project)
    end

    def leavers_with_increased_income(field, project: nil)
      increased_income(field, :income_leaver, __method__, project: project)
    end

    def increased_income(income_field, status_field, meth, project: nil)
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
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
      )
    end

    def result_for(field, project_id: nil)
      return results.find_by(field: field, system_level: true) if project_id.blank?

      results.find_by(field: field, project_id: project_id)
    end

    def save_results
      results = result_methods.map { |method, field| send(method, field) }
      projects.preload(:hud_project).each do |project|
        result_methods.each do |method, field|
          results << send(method, field, project: project)
        end
      end
      PerformanceMeasurement::Result.transaction do
        PerformanceMeasurement::Result.where(report_id: id).delete_all
        PerformanceMeasurement::Result.import!(results.compact, batch_size: 5_000)
      end
    end

    private def result_methods
      {
        count_of_sheltered_homeless_clients: :served_on_pit_date_sheltered,
        count_of_homeless_clients: :served_on_pit_date,
        count_of_unsheltered_homeless_clients: :served_on_pit_date_unsheltered,
        first_time_homeless_clients: :first_time,
        length_of_homeless_time_homeless_average: :days_homeless_es_sh_th,
        length_of_homeless_time_homeless_median: :days_homeless_es_sh_th,
        time_to_move_in_average: :days_homeless_es_sh_th_ph,
        time_to_move_in_median: :days_homeless_es_sh_th_ph,
        so_positive_destinations: :so_destination_positive,
        es_sh_th_rrh_positive_destinations: :es_sh_th_rrh_destination_positive,
        moved_in_positive_destinations: :moved_in_destination_positive,
        returned_in_six_months: :returned_in_six_months,
        returned_in_two_years: :returned_in_two_years,
        stayers_with_increased_income: :increased_income__income_stayer,
        leavers_with_increased_income: :increased_income__income_leaver,
        length_of_homeless_stay_average: :days_in_homeless_bed,
        length_of_homeless_stay_median: :days_in_homeless_bed,
      }
    end
  end
end
