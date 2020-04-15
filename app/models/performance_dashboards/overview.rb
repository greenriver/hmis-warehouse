###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class PerformanceDashboards::Overview < PerformanceDashboards::Base
  include PerformanceDashboard::Overview::Age
  include PerformanceDashboard::Overview::Gender
  include PerformanceDashboard::Overview::Household
  include PerformanceDashboard::Overview::Veteran
  include PerformanceDashboard::Overview::Detail
  include PerformanceDashboard::Overview::Entering
  include PerformanceDashboard::Overview::Exiting

  def self.detail_method(key)
    available_keys[key.to_sym]
  end

  def self.available_keys
    {
      entering: :entering,
      exiting: :exiting,
    }
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
    report_scope(all_project_types: true).homeless
  end

  def newly_homeless
    previous_period = report_scope_source.
      entry_within_date_range(start_date: @start_date - 24.months, end_date: @start_date - 1.day).
      homeless

    homeless.
      where.not(client_id: previous_period.select(:client_id))
  end

  def literally_homeless
    report_scope(all_project_types: true).homeless(chronic_types_only: true)
  end

  def newly_literally_homeless
    previous_period = report_scope_source.
      entry_within_date_range(start_date: @start_date - 24.months, end_date: @start_date - 1.day).
      homeless(chronic_types_only: true)

    literally_homeless.
      where.not(client_id: previous_period.select(:client_id))
  end

  def housed
    exits.where.not(move_in_date: nil).
      or(exits.where(housing_status_at_exit: 4)) # Stably housed
  end

  # An entry is an enrollment where the entry date is within the report range, and there are no entries in the
  # specified project types for the prior 24 months.
  def entries
    previous_period = report_scope_source.
      entry_within_date_range(start_date: @start_date - 24.months, end_date: @start_date - 1.day).
      where(project_type: @project_types)

    entries_current_period.where.not(client_id: previous_period.select(:client_id))
  end

  def entries_current_period
    report_scope.entry
  end

  # An exit is an enrollment where the exit date is within the report range, and there are no enrollments in the
  # specified project types that were open after the reporting period.
  def exits
    next_period = report_scope_source.
      open_between(start_date: @end_date + 1.day, end_date: Date.current).
      where(project_type: @project_types)

    exits_current_period.where.not(client_id: next_period.select(:client_id))
  end

  def exits_current_period
    report_scope.exit
  end
end