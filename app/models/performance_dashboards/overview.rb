###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class PerformanceDashboards::Overview < PerformanceDashboards::Base
  include PerformanceDashboardOverviewDetail

  def self.detail_method(key)
    available_keys[key.to_sym]
  end

  def self.available_keys
    {
      entering: :entering,
    }
  end

  def entering
    entries.distinct
  end

  def entering_by_age_total_count
    entering.pluck(:client_id, :age).uniq.count
  end

  def entering_by_age
    buckets = buckets = age_buckets.map{|b| [b, []]}.to_h
    counted = []
    entering.order(age: :desc).pluck(:client_id, :age).each do |(id, age)|
      buckets[age_bucket(age)] << id unless id.in?(counted)
      counted << id
    end
    buckets
  end

  def entering_by_age_data_for_chart
    columns = [(@start_date..@end_date).to_s]
    columns += entering_by_age.values
  end

  def exiting
    exits.distinct
  end

  def exiting_by_age
    buckets = age_buckets.map{|b| [b, []]}.to_h
    exiting.pluck(:client_id, :age).each do |(id, age, _destination)|
      buckets[age_bucket(age)] << id
    end
    buckets
  end

  private def age_buckets
    [
      :under_eighteen,
      :eighteen_to_twenty_four,
      :twenty_five_to_sixty_one,
      :over_sixty_one,
      :unknown,
    ]
  end

  def age_bucket(age)
    return :unknown unless age

    if age < 18
      :under_eighteen
    elsif age >= 18 && age <= 24
      :eighteen_to_twenty_four
    elsif age >= 25 && age <= 61
      :twenty_five_to_sixty_one
    else
      :over_sixty_one
    end
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

    report_scope.
      entry.
      where.not(client_id: previous_period.select(:client_id))
  end

  # An exit is an enrollment where the exit date is within the report range, and there are no enrollments in the
  # specified project types that were open after the reporting period.
  def exits
    next_period = report_scope_source.
      open_between(start_date: @end_date + 1.day, end_date: Date.current).
      where(project_type: @project_types)

    report_scope.
      exit.
      where.not(client_id: next_period.select(:client_id))
  end
end