###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement::ResultCalculation
  extend ActiveSupport::Concern

  included do
    # accepts goal_method, reporting_value, and optional comparison_value
    # returns { passed: boolean, goal: goal_value, progress: progress_value }
    def calculate_processed(goal_method, reporting_value, comparison_value = nil)
      goal_value = goal(goal_method)
      progress = nil
      passed = case goal_method.to_sym
      # increase year over year
      when
        :income
        progress = percent_changed(reporting_value, comparison_value)
        progress >= goal_value
      # decrease year over year
      when :people
        progress = percent_changed(reporting_value, comparison_value)
        progress <= - goal_value
      # less than or equal to goal
      when :time_time,
        :time_stay,
        :time_move_in,
        :recidivism_6_months,
        :recidivism_24_months
        progress = reporting_value
        progress <= goal_value
      # greater than or equal to goal
      when :capacity,
        :destination
        progress = reporting_value
        progress >= goal_value
      else
        raise "#{goal_method} is undefined for calculate_processed"
      end
      {
        passed: passed,
        goal: goal_value,
        progress: progress,
      }
    end

    def goal(field)
      goal_config[field]
    end

    def direction(_field, reporting_value, comparison_value)
      if reporting_value == comparison_value
        :none
      elsif reporting_value < comparison_value
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

    def inventory_sum(field, period, project_id: nil, project_type:)
      column = "#{period}_#{field}"
      project_scope = projects.joins(:hud_project).merge(GrdaWarehouse::Hud::Project.send(project_type))
      return project_scope.sum(column) if project_id.blank?

      @inventory_sum ||= {}
      @inventory_sum[column] ||= {}
      @inventory_sum[column][project_type] ||= project_scope.group(:project_id).sum(column)
      @inventory_sum[column][project_type][project_id] || 0
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

    def count_of_sheltered_homeless_clients(detail, project: nil)
      field = detail[:calculation_column]
      reporting_count = client_count(field, :reporting, project_id: project&.project_id)
      comparison_count = client_count(field, :comparison, project_id: project&.project_id)

      progress = calculate_processed(detail[:goal_calculation], reporting_count, comparison_count)
      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        direction: direction(field, reporting_count, comparison_count),
        primary_value: reporting_count,
        primary_unit: 'clients',
        secondary_value: progress,
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_count,
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        passed: progress[:passed],
        goal: progress[:goal],
        goal_progress: progress[:progress],
      )
    end

    # NOTE: SPM does not include SO, so this needs to be done based on SHS
    def count_of_homeless_clients(detail, project: nil)
      return unless project.blank? || project.hud_project&.es? || project.hud_project&.sh? || project.hud_project&.th?

      field = detail[:calculation_column]

      reporting_count = client_count(field, :reporting, project_id: project&.project_id)
      comparison_count = client_count(field, :comparison, project_id: project&.project_id)

      progress = calculate_processed(detail[:goal_calculation], reporting_count, comparison_count)
      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        direction: direction(field, reporting_count, comparison_count),
        primary_value: reporting_count,
        primary_unit: 'clients',
        secondary_value: progress,
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_count,
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        passed: progress[:passed],
        goal: progress[:goal],
        goal_progress: progress[:progress],
      )
    end

    # NOTE: SPM does not include SO, so this needs to be done based on SHS
    def count_of_unsheltered_homeless_clients(detail, project: nil)
      return unless project.blank? || project.hud_project&.so?

      field = detail[:calculation_column]

      reporting_count = client_count(field, :reporting, project_id: project&.project_id)
      comparison_count = client_count(field, :comparison, project_id: project&.project_id)

      progress = calculate_processed(detail[:goal_calculation], reporting_count, comparison_count)
      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        direction: direction(field, reporting_count, comparison_count),
        primary_value: reporting_count,
        primary_unit: 'clients',
        secondary_value: progress,
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_count,
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        passed: progress[:passed],
        goal: progress[:goal],
        goal_progress: progress[:progress],
      )
    end

    def first_time_homeless_clients(detail, project: nil)
      field = detail[:calculation_column]
      reporting_count = client_count(field, :reporting, project_id: project&.project_id)
      comparison_count = client_count(field, :comparison, project_id: project&.project_id)

      progress = calculate_processed(detail[:goal_calculation], reporting_count, comparison_count)
      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        direction: direction(field, reporting_count, comparison_count),
        primary_value: reporting_count,
        primary_unit: 'clients',
        secondary_value: progress,
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_count,
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        passed: progress[:passed],
        goal: progress[:goal],
        goal_progress: progress[:progress],
      )
    end

    def length_of_homeless_time_homeless_average(detail, project: nil)
      return unless project.blank? || project.hud_project&.es? || project.hud_project&.sh? || project.hud_project&.th?

      field = detail[:calculation_column]

      reporting_count = client_count_present(field, :reporting, project_id: project&.project_id)
      comparison_count = client_count_present(field, :comparison, project_id: project&.project_id)
      reporting_days = client_sum(field, :reporting, project_id: project&.project_id)
      comparison_days = client_sum(field, :comparison, project_id: project&.project_id)
      reporting_average = average(reporting_days, reporting_count)
      comparison_average = average(comparison_days, comparison_count)

      progress = calculate_processed(detail[:goal_calculation], reporting_average, nil)
      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        direction: direction(field, reporting_average, comparison_average),
        primary_value: reporting_average,
        primary_unit: 'days',
        secondary_value: percent_changed(reporting_average, comparison_average),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_average,
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        passed: progress[:passed],
        goal: progress[:goal],
        goal_progress: progress[:progress],
      )
    end

    def length_of_homeless_time_homeless_median(detail, project: nil)
      return unless project.blank? || project.hud_project&.es? || project.hud_project&.sh? || project.hud_project&.th?

      field = detail[:calculation_column]

      reporting_days = client_data(field, :reporting, project_id: project&.project_id)
      comparison_days = client_data(field, :comparison, project_id: project&.project_id)

      reporting_median = median(reporting_days)
      comparison_median = median(comparison_days)

      progress = calculate_processed(detail[:goal_calculation], reporting_median, nil)
      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        direction: direction(field, reporting_median, comparison_median),
        primary_value: reporting_median,
        primary_unit: 'days',
        secondary_value: percent_changed(reporting_median, comparison_median),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_median,
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        passed: progress[:passed],
        goal: progress[:goal],
        goal_progress: progress[:progress],
      )
    end

    def length_of_homeless_stay_average(detail, project: nil)
      return unless project.blank? || project.hud_project&.es? || project.hud_project&.sh? || project.hud_project&.th?

      field = detail[:calculation_column]

      reporting_count = client_count_present(field, :reporting, project_id: project&.project_id)
      comparison_count = client_count_present(field, :comparison, project_id: project&.project_id)
      reporting_days = client_sum(field, :reporting, project_id: project&.project_id)
      comparison_days = client_sum(field, :comparison, project_id: project&.project_id)
      reporting_average = average(reporting_days, reporting_count)
      comparison_average = average(comparison_days, comparison_count)

      progress = calculate_processed(detail[:goal_calculation], reporting_average, nil)
      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        direction: direction(field, reporting_average, comparison_average),
        primary_value: reporting_average,
        primary_unit: 'days',
        secondary_value: percent_changed(reporting_average, comparison_average),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_average,
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        passed: progress[:passed],
        goal: progress[:goal],
        goal_progress: progress[:progress],
      )
    end

    def length_of_homeless_stay_median(detail, project: nil)
      return unless project.blank? || project.hud_project&.es? || project.hud_project&.sh? || project.hud_project&.th?

      field = detail[:calculation_column]

      reporting_days = client_data(field, :reporting, project_id: project&.project_id)
      comparison_days = client_data(field, :comparison, project_id: project&.project_id)

      reporting_median = median(reporting_days)
      comparison_median = median(comparison_days)

      progress = calculate_processed(detail[:goal_calculation], reporting_median, nil)
      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        direction: direction(field, reporting_median, comparison_median),
        primary_value: reporting_median,
        primary_unit: 'days',
        secondary_value: percent_changed(reporting_median, comparison_median),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_median,
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        passed: progress[:passed],
        goal: progress[:goal],
        goal_progress: progress[:progress],
      )
    end

    def time_to_move_in_average(detail, project: nil)
      return unless project.blank? || project.hud_project&.es? || project.hud_project&.sh? || project.hud_project&.th? || project.hud_project&.ph?

      field = detail[:calculation_column]

      reporting_count = client_count_present(field, :reporting, project_id: project&.project_id)
      comparison_count = client_count_present(field, :comparison, project_id: project&.project_id)
      reporting_days = client_sum(field, :reporting, project_id: project&.project_id)
      comparison_days = client_sum(field, :comparison, project_id: project&.project_id)
      reporting_average = average(reporting_days, reporting_count)
      comparison_average = average(comparison_days, comparison_count)

      progress = calculate_processed(detail[:goal_calculation], reporting_average, nil)
      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        direction: direction(field, reporting_average, comparison_average),
        primary_value: reporting_average,
        primary_unit: 'days',
        secondary_value: percent_changed(reporting_average, comparison_average),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_average,
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        passed: progress[:passed],
        goal: progress[:goal],
        goal_progress: progress[:progress],
      )
    end

    def time_to_move_in_median(detail, project: nil)
      return unless project.blank? || project.hud_project&.es? || project.hud_project&.sh? || project.hud_project&.th? || project.hud_project&.ph?

      field = detail[:calculation_column]

      reporting_days = client_data(field, :reporting, project_id: project&.project_id)
      comparison_days = client_data(field, :comparison, project_id: project&.project_id)

      reporting_median = median(reporting_days)
      comparison_median = median(comparison_days)

      progress = calculate_processed(detail[:goal_calculation], reporting_median, nil)
      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        direction: direction(field, reporting_median, comparison_median),
        primary_value: reporting_median,
        primary_unit: 'days',
        secondary_value: percent_changed(reporting_median, comparison_median),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_median,
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        passed: progress[:passed],
        goal: progress[:goal],
        goal_progress: progress[:progress],
      )
    end

    def so_positive_destinations(detail, project: nil)
      return unless project.blank? || project.hud_project&.so?

      field = detail[:calculation_column]

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

      progress = calculate_processed(detail[:goal_calculation], reporting_percent, nil)
      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        direction: direction(field, reporting_percent, comparison_percent),
        primary_value: reporting_numerator,
        primary_unit: 'clients',
        secondary_value: percent_changed(reporting_denominator, comparison_denominator),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_numerator,
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        passed: progress[:passed],
        goal: progress[:goal],
        goal_progress: progress[:progress],
      )
    end

    def es_sh_th_rrh_positive_destinations(detail, project: nil)
      return unless project.blank? || project.hud_project&.es? || project.hud_project&.sh? || project.hud_project&.th? || project.hud_project&.rrh?

      field = detail[:calculation_column]

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

      progress = calculate_processed(detail[:goal_calculation], reporting_percent, nil)
      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        direction: direction(field, reporting_percent, comparison_percent),
        primary_value: reporting_numerator,
        primary_unit: 'clients',
        secondary_value: percent_changed(reporting_denominator, comparison_denominator),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_numerator,
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        passed: progress[:passed],
        goal: progress[:goal],
        goal_progress: progress[:progress],
      )
    end

    def moved_in_positive_destinations(detail, project: nil)
      return unless project.blank? || project.hud_project&.ph?

      field = detail[:calculation_column]

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

      progress = calculate_processed(detail[:goal_calculation], reporting_percent, nil)
      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        direction: direction(field, reporting_percent, comparison_percent),
        primary_value: reporting_numerator,
        primary_unit: 'clients',
        secondary_value: percent_changed(reporting_denominator, comparison_denominator),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_numerator,
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        passed: progress[:passed],
        goal: progress[:goal],
        goal_progress: progress[:progress],
      )
    end

    def returned_in_six_months(detail, project: nil)
      returned_in_range(detail, __method__, project: project)
    end

    def returned_in_two_years(detail, project: nil)
      returned_in_range(detail, __method__, project: project)
    end

    def returned_in_range(detail, meth, project: nil)
      field = detail[:calculation_column]
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

      progress = calculate_processed(detail[:goal_calculation], reporting_percent, nil)
      PerformanceMeasurement::Result.new(
        report_id: id,
        field: meth,
        title: detail_title_for(meth.to_sym),
        direction: direction(field, reporting_percent, comparison_percent),
        primary_value: reporting_numerator,
        primary_unit: 'clients',
        secondary_value: percent_changed(reporting_denominator, comparison_denominator),
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_numerator,
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        passed: progress[:passed],
        goal: progress[:goal],
        goal_progress: progress[:progress],
      )
    end

    def es_average_bed_utilization(detail, project: nil)
      return unless project.blank? || project.hud_project&.es?

      average_bed_utilization(detail, __method__, project_type: :es, project: project)
    end

    def sh_average_bed_utilization(detail, project: nil)
      return unless project.blank? || project.hud_project&.sh?

      average_bed_utilization(detail, __method__, project_type: :sh, project: project)
    end

    def th_average_bed_utilization(detail, project: nil)
      return unless project.blank? || project.hud_project&.th?

      average_bed_utilization(detail, __method__, project_type: :th, project: project)
    end

    def average_bed_utilization(detail, meth, project_type:, project: nil)
      field = detail[:calculation_column]
      day_count = filter.range.count
      reporting_days = client_sum(field, :reporting, project_id: project&.project_id)
      reporting_inventory = inventory_sum(:ave_bed_capacity_per_night, :reporting, project_id: project&.project_id, project_type: project_type)
      comparison_days = client_sum(field, :comparison, project_id: project&.project_id)
      comparison_inventory = inventory_sum(:ave_bed_capacity_per_night, :comparison, project_id: project&.project_id, project_type: project_type)

      reporting_denominator = reporting_inventory
      reporting_numerator = reporting_days / day_count.to_f
      reporting_percent = percent_of(reporting_numerator, reporting_denominator)

      comparison_denominator = comparison_inventory
      comparison_numerator = comparison_days / day_count.to_f
      comparison_percent = percent_of(comparison_numerator, comparison_denominator)

      progress = calculate_processed(detail[:goal_calculation], reporting_percent, nil)
      PerformanceMeasurement::Result.new(
        report_id: id,
        field: meth,
        title: detail_title_for(meth.to_sym),
        direction: direction(field, reporting_percent, comparison_percent),
        primary_value: reporting_percent,
        primary_unit: '%',
        secondary_value: nil,
        secondary_unit: nil,
        value_label: 'Change over year',
        comparison_primary_value: percent_changed(reporting_denominator, comparison_denominator),
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        passed: progress[:passed],
        goal: progress[:goal],
        goal_progress: progress[:progress],
      )
    end

    def overall_average_bed_utilization(detail, project: nil)
      return unless project.blank?

      field = detail[:calculation_column]

      day_count = filter.range.count
      a_t = PerformanceMeasurement::Client.arel_table
      bed_columns = [
        :days_in_es_bed_in_period,
        :days_in_sh_bed_in_period,
        :days_in_th_bed_in_period,
      ]
      columns = bed_columns.map { |f| cl(a_t["reporting_#{f}"], 0).to_sql }
      (reporting_days, comparison_days) = [:reporting, :comparison].map do |period|
        clients.joins(:client_projects).
          merge(
            PerformanceMeasurement::ClientProject.
              where(period: period, for_question: bed_columns),
          ).sum(Arel.sql(columns.join(' + ')))
      end

      reporting_inventory = 0
      comparison_inventory = 0
      [
        :es,
        :sh,
        :th,
      ].each do |project_type|
        reporting_inventory += inventory_sum(:ave_bed_capacity_per_night, :reporting, project_type: project_type)
        comparison_inventory += inventory_sum(:ave_bed_capacity_per_night, :comparison, project_type: project_type)
      end

      reporting_denominator = reporting_inventory
      reporting_numerator = reporting_days / day_count.to_f
      reporting_percent = percent_of(reporting_numerator, reporting_denominator)

      comparison_denominator = comparison_inventory
      comparison_numerator = comparison_days / day_count.to_f
      comparison_percent = percent_of(comparison_numerator, comparison_denominator)

      progress = calculate_processed(detail[:goal_calculation], reporting_percent, nil)
      PerformanceMeasurement::Result.new(
        report_id: id,
        field: __method__,
        title: detail_title_for(__method__.to_sym),
        direction: direction(field, reporting_percent, comparison_percent),
        primary_value: reporting_percent,
        primary_unit: '%',
        secondary_value: percent_changed(reporting_denominator, comparison_denominator),
        secondary_unit: nil,
        value_label: 'Change over year',
        comparison_primary_value: comparison_percent,
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        passed: progress[:passed],
        goal: progress[:goal],
        goal_progress: progress[:progress],
      )
    end

    def stayers_with_increased_income(detail, project: nil)
      increased_income(detail, :income_stayer, __method__, project: project)
    end

    def leavers_with_increased_income(detail, project: nil)
      increased_income(detail, :income_leaver, __method__, project: project)
    end

    def increased_income(detail, status_field, meth, project: nil)
      income_field = detail[:calculation_column]
      reporting_denominator = client_count(status_field, :reporting, project_id: project&.project_id)
      comparison_denominator = client_count(status_field, :comparison, project_id: project&.project_id)
      reporting_numerator = client_count(income_field, :reporting, project_id: project&.project_id)
      comparison_numerator = client_count(income_field, :comparison, project_id: project&.project_id)

      reporting_percent = percent_of(reporting_numerator, reporting_denominator)
      comparison_percent = percent_of(comparison_numerator, comparison_denominator)

      progress = calculate_processed(detail[:goal_calculation], reporting_percent, comparison_percent)
      PerformanceMeasurement::Result.new(
        report_id: id,
        field: meth,
        title: detail_title_for(meth.to_sym),
        direction: direction(income_field, reporting_percent, comparison_percent),
        primary_value: reporting_numerator,
        primary_unit: 'clients',
        secondary_value: progress[:progress],
        secondary_unit: '%',
        value_label: 'Change over year',
        comparison_primary_value: comparison_numerator,
        system_level: project&.project_id.blank?,
        project_id: project&.project_id,
        passed: progress[:passed],
        goal: progress[:goal],
        goal_progress: progress[:progress],
      )
    end

    def result_for(field, project_id: nil)
      return results.find_by(field: field, system_level: true) if project_id.blank?

      results.find_by(field: field, project_id: project_id)
    end

    def save_results
      results = result_methods.map { |method, row| send(method, row) }
      projects.preload(:hud_project).each do |project|
        result_methods.each do |method, row|
          results << send(method, row, project: project)
        end
      end
      PerformanceMeasurement::Result.transaction do
        PerformanceMeasurement::Result.where(report_id: id).delete_all
        PerformanceMeasurement::Result.import!(results.compact, batch_size: 5_000)
      end
    end

    private def result_methods
      detail_hash.map { |k, row| [k, row] }.to_h.freeze
    end
  end
end
