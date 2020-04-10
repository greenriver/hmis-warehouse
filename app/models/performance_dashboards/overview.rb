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

  def entering_total_count
    entering.select(:client_id).count
  end

  # NOTE: always count the most-recently started enrollment within the range
  def entering_by_age
    buckets = buckets = age_buckets.map{|b| [b, []]}.to_h
    counted = Set.new
    entering.order(first_date_in_program: :desc).
      pluck(:client_id, :age, :first_date_in_program).each do |id, age, _|
      buckets[age_bucket(age)] << id unless counted.include?(id)
      counted << id
    end
    buckets
  end

  def entering_by_age_data_for_chart
    @entering_by_age_data_for_chart ||= begin
      columns = [(@start_date..@end_date).to_s]
      columns += entering_by_age.values.map(&:count)
      {
      columns: columns,
      categories: entering_by_age.keys.map(&:to_s).map(&:humanize),
      }
    end
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

  def age_bucket_titles
    age_buckets.map do |key|
      [
        key,
        key.to_s.humanize
      ]
    end.to_h
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

  def age_query(key)
    return '0=1' unless key

    @age_queries ||= {
      under_eighteen: she_t[:age].lt(18),
      eighteen_to_twenty_four: she_t[:age].between(18..24),
      twenty_five_to_sixty_one: she_t[:age].between(25..61),
      over_sixty_one: she_t[:age].gt(61),
      unknown: she_t[:age].eq(nil),
    }
    @age_queries[key.to_sym]
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