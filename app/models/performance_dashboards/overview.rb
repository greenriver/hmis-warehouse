###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PerformanceDashboards::Overview < PerformanceDashboards::Base
  include PerformanceDashboard::Overview::Age
  include PerformanceDashboard::Overview::Gender
  include PerformanceDashboard::Overview::Household
  include PerformanceDashboard::Overview::Veteran
  include PerformanceDashboard::Overview::Race
  include PerformanceDashboard::Overview::Ethnicity
  include PerformanceDashboard::Overview::Detail
  include PerformanceDashboard::Overview::Entering
  include PerformanceDashboard::Overview::Exiting
  include PerformanceDashboard::Overview::Enrolled
  include PerformanceDashboard::Overview::ProjectType
  include PerformanceDashboard::Overview::Coc
  include PerformanceDashboard::Overview::LotHomeless

  def self.url
    'performance_dashboards/overview'
  end

  def self.available_keys
    {
      entering: :entering,
      exiting: :exiting,
    }
  end

  def report_path_array
    [
      :performance,
      :dashboards,
      :overview,
      :index,
    ]
  end

  def self.available_chart_types
    chart_types = [
      'by_age',
      'by_ethnicity',
      'by_gender',
      'by_household',
      'by_race',
      'by_veteran',
      'by_project_type',
      'by_lot_homeless',
    ]
    # Only show CoC tab if the site is setup to show it
    chart_types << 'by_coc' if GrdaWarehouse::Config.get(:multi_coc_installation)
    chart_types
  end

  protected def build_control_sections
    [
      build_general_control_section(include_inactivity_days: true),
      build_coc_control_section,
      build_household_control_section,
      build_demographics_control_section,
    ]
  end

  def exiting_by_destination
    destinations = {}
    exiting.pluck(:client_id, :destination).each do |id, destination|
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
    homeless.distinct.select(:client_id).count
  end

  def newly_homeless
    previous_period = report_scope_source.
      entry_within_date_range(start_date: @start_date - 24.months, end_date: @start_date - 1.day).
      with_service_between(start_date: @start_date - 24.months, end_date: @start_date - 1.day).
      homeless

    homeless.where.not(period_exists_sql(previous_period))
  end

  def newly_homeless_count
    newly_homeless.distinct.select(:client_id).count
  end

  def literally_homeless
    report_scope(all_project_types: true).
      with_service_between(start_date: @start_date, end_date: @end_date).
      homeless(chronic_types_only: true)
  end

  def literally_homeless_count
    literally_homeless.distinct.select(:client_id).count
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
    newly_literally_homeless.distinct.select(:client_id).count
  end

  def housed
    report_scope.
      with_service_between(start_date: @start_date, end_date: @end_date).
      where.not(move_in_date: filter.range).
      or(exits.where(housing_status_at_exit: 4)) # Stably housed
  end

  def housed_count
    housed.distinct.select(:client_id).count
  end

  def available_breakdowns
    breakdowns = {
      age: 'By Age',
      gender: 'By Gender',
      household: 'By Household Type',
      veteran: 'By Veteran Status',
      race: 'By Race',
      ethnicity: 'By Ethnicity',
      project_type: 'By Project Type',
      lot_homeless: 'By LOT Homeless',
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
