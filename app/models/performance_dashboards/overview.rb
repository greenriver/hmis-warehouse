###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PerformanceDashboards::Overview < PerformanceDashboards::Base
  include PerformanceDashboard::Overview::Age
  include PerformanceDashboard::Overview::Gender
  include PerformanceDashboard::Overview::Household
  include PerformanceDashboard::Overview::Veteran
  include PerformanceDashboard::Overview::RaceAndEthnicity
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
      'by_gender',
      'by_household',
      'by_race_and_ethnicity',
      'by_race',
      'by_ethnicity',
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
      build_general_control_section(options: { include_inactivity_days: true }),
      build_coc_control_section,
      add_demographic_disabilities_control_section,
    ]
  end

  def available_breakdowns
    breakdowns = {
      age: 'By Age',
      gender: 'By Gender',
      household: 'By Household Type',
      veteran: 'By Veteran Status',
      race_and_ethnicity: 'By Race and Ethnicity',
      race: 'By Race Overall',
      ethnicity: 'By Ethnicity Overall',
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
