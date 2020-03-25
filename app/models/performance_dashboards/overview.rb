###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class PerformanceDashboards::Overview < PerformanceDashboards::Base

  def entering(by_enrollment: false)
    @entering ||= if by_enrollment
      entries.pluck(:id, :age)
    else
      entries.pluck(:client_id, :age)
    end
  end

  def entering_by_age(by_enrollment: false)
    buckets = {
      under_eighteen: [],
      eighteen_to_twenty_four: [],
      twenty_five_to_sixty_one: [],
      over_sixty_one: [],
    }
    entering(by_enrollment: by_enrollment).each do |(id, age)|
      next if age.blank?
      buckets[:under_eighteen] << id if age < 18
      buckets[:eighteen_to_twenty_four] << id if age >= 18 && age <= 24
      buckets[:twenty_five_to_sixty_one] << id if age >= 25 && age <= 61
      buckets[:over_sixty_one] << id if age > 61
    end
    buckets
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