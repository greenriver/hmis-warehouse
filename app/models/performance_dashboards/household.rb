###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PerformanceDashboards::Household < PerformanceDashboards::Base
  include PerformanceDashboard::Household::Household
  include PerformanceDashboard::Household::Detail
  include PerformanceDashboard::Household::Entering
  include PerformanceDashboard::Household::Exiting
  include PerformanceDashboard::Household::Enrolled
  include PerformanceDashboard::Household::ProjectType
  include PerformanceDashboard::Household::Coc

  def self.url
    'performance_dashboards/household'
  end

  def self.available_keys
    {
      entering: :entering,
      exiting: :exiting,
    }
  end

  def performance_type
    'Household'
  end

  def report_path_array
    [
      :performance,
      :dashboards,
      :household,
      :index,
    ]
  end

  def self.available_chart_types
    chart_types = [
      'by_household',
      'by_project_type',
    ]
    # Only show CoC tab if the site is setup to show it
    chart_types << 'by_coc' if GrdaWarehouse::Config.get(:multi_coc_installation)
    chart_types
  end

  protected def build_control_sections
    [
      build_general_control_section,
      build_coc_control_section,
      build_household_control_section,
      build_demographics_control_section,
    ]
  end

  protected def build_demographics_control_section
    ::Filters::UiControlSection.new(id: 'demographics').tap do |section|
      section.add_control(
        id: 'sub_population',
        label: 'Sub-Population',
        short_label: 'Sub-Population',
        required: true,
        value: @filter.sub_population == :clients ? nil : @filter.chosen_sub_population,
      )
    end
  end

  protected def build_household_control_section
    ::Filters::UiControlSection.new(id: 'household').tap do |section|
      section.add_control(id: 'household_type', required: true, value: @filter.household_type == :all ? nil : @filter.chosen_household_type)
    end
  end

  def exiting_by_destination
    destinations = {}
    exiting.pluck(:household_id, :destination).each do |id, destination|
      destinations[destination] ||= []
      destinations[destination] << id
    end
    destinations
  end

  def homeless
    report_scope(all_project_types: true).
      with_service_between(start_date: @start_date, end_date: @end_date).
      homeless
  end

  def homeless_count
    homeless.distinct.select(:household_id).count
  end

  def newly_homeless
    previous_period = report_scope_source.
      entry_within_date_range(start_date: @start_date - 24.months, end_date: @start_date - 1.day).
      with_service_between(start_date: @start_date - 24.months, end_date: @start_date - 1.day).
      homeless

    homeless.where.not(period_exists_sql(previous_period))
  end

  def newly_homeless_count
    newly_homeless.distinct.select(:household_id).count
  end

  def literally_homeless
    report_scope(all_project_types: true).
      with_service_between(start_date: @start_date, end_date: @end_date).
      homeless(chronic_types_only: true)
  end

  def literally_homeless_count
    literally_homeless.distinct.select(:household_id).count
  end

  def newly_literally_homeless
    previous_period = report_scope_source.
      entry_within_date_range(start_date: @start_date - 24.months, end_date: @start_date - 1.day).
      with_service_between(start_date: @start_date - 24.months, end_date: @start_date - 1.day).
      homeless(chronic_types_only: true)

    literally_homeless.
      where.not(period_exists_sql(previous_period))
  end

  def newly_literally_homeless_count
    newly_literally_homeless.distinct.select(:household_id).count
  end

  def housed
    report_scope.
      with_service_between(start_date: @start_date, end_date: @end_date).
      where.not(move_in_date: filter.range).
      or(exits.where(housing_status_at_exit: 4)) # Stably housed
  end

  def housed_count
    housed.distinct.select(:household_id).count
  end

  def available_breakdowns
    breakdowns = {
      household: 'By Household Type',
      project_type: 'By Project Type',
    }

    # Only show CoC tab if the site is setup to show it
    breakdowns[:coc] = 'By CoC' if GrdaWarehouse::Config.get(:multi_coc_installation)
    breakdowns
  end

  protected def filter_selected_data_for_chart(data)
    labels = data.delete(:labels) || {}
    chosen = data.delete(:chosen)&.to_set
    chosen&.delete(:all)
    if chosen.present?
      (columns, categories) = data.values_at(:columns, :categories)
      initial_categories = categories.dup
      date = columns.shift
      filtered = columns.zip(categories).select { |_, cat| cat.in?(chosen) }
      data[:columns] = [date] + filtered.map(&:first)
      data[:categories] = filtered.map(&:last)
      excluded_categories = initial_categories - data[:categories]
      if excluded_categories.present?
        # FIXME: - pack this option into the columns so I don't have to modify 20+ calls in partials
        excluded_categories.map! { |s| labels.fetch(s, s) }
        data[:categories].unshift({ excluded_categories: excluded_categories })
      end
    end
    data[:categories].map! { |s| labels.fetch(s, s) }
    data
  end
end
