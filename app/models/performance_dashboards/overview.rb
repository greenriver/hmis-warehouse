###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class PerformanceDashboards::Overview < PerformanceDashboards::Base # rubocop:disable Style/ClassAndModuleChildren
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
end
