###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::EnrollmentFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:with_statuses)).
      yield_self(&method(:with_open_on_date)).
      yield_self(&method(:with_bed_night_on_date)).
      yield_self(&method(:with_project_types)).
      yield_self(&method(:with_search_term)).
      yield_self(&method(:with_household_tasks)).
      yield_self(&method(:with_assigned_staff)).
      yield_self(&method(:clean_scope))
  end

  protected

  def with_statuses(scope)
    with_filter(scope, :status) do
      if input.status.present?
        ids = []

        ids += scope.open_excluding_wip.pluck(:id) if input.status.include?('ACTIVE')
        ids += scope.incomplete.pluck(:id) if input.status.include?('INCOMPLETE')
        ids += scope.exited.pluck(:id) if input.status.include?('EXITED')

        return scope.where(id: ids)
      end

      scope
    end
  end

  def with_open_on_date(scope)
    with_filter(scope, :open_on_date) { scope.open_on_date(input.open_on_date) }
  end

  def with_bed_night_on_date(scope)
    with_filter(scope, :bed_night_on_date) { scope.bed_night_on_date(input.bed_night_on_date) }
  end

  def with_project_types(scope)
    with_filter(scope, :project_type) { scope.with_project_type(input.project_type) }
  end

  def with_search_term(scope)
    with_filter(scope, :search_term) { scope.matching_search_term(input.search_term) }
  end

  def today
    @today ||= Date.current
  end

  def with_household_tasks(scope)
    with_filter(scope, :household_tasks) do
      return scope.all unless input.household_tasks&.include?('ANNUAL_DUE')

      # SQL-ized version of the logic here: drivers/hmis/app/models/hmis/reminders/reminder_generator.rb#annual_assessment_reminder

      # The SQL statement "interval"((extract(day from "EntryDate")::integer - 1) || ' days') is present to handle leap
      # year dates. That is, if the entry date is 2/29/2020, then just using make_date directly will produce an
      # anniversary date of 2/29/2023, which is invalid. To prevent this, make_date is used to create a date of
      # 2/1/2023, then we add 28 days (29th - 1) to that date to shift it to the proper anniversary date. For any date
      # except for 2/29, this shift should result in the same month and day as the entry date, and for 2/29 it should
      # shift it to 3/1, which is a valid date and avoids the leap year issue.

      anniversary_date = <<~SQL
        make_date(
          #{scope.connection.quote(today.year)}::integer,
          extract(month from "earliest_entry")::integer,
          1
        ) + "interval"((extract(day from "earliest_entry")::integer - 1) || ' days')
      SQL
      last_year_anniversary_date = <<~SQL
        #{anniversary_date} - interval '1 year'
      SQL

      # Due period for the 60-day window during which this year's Annual should be performed
      start_date = Arel.sql <<~SQL
        #{anniversary_date} - interval '30 days'
      SQL
      end_date = Arel.sql <<~SQL
        #{anniversary_date} + interval '30 days'
      SQL

      # Due period for the 60-day window during which last year's Annual should have been performed
      last_start_date = Arel.sql <<~SQL
        #{last_year_anniversary_date} - interval '30 days'
      SQL
      last_end_date = Arel.sql <<~SQL
        #{last_year_anniversary_date} + interval '30 days'
      SQL

      # Clause for checking whether an Assessment falls within the "due period". There are two cases because the due period may be this year or last year.
      this_year_annual_in_range = start_date.lteq(today).and(cas_t[:assessment_date].gteq(start_date).and(cas_t[:assessment_date].lteq(end_date)))
      last_year_annual_in_range = start_date.gt(today).and(cas_t[:assessment_date].gteq(last_start_date).and(cas_t[:assessment_date].lteq(last_end_date)))
      annual_in_range = this_year_annual_in_range.or(last_year_annual_in_range)

      # Clause for checking whether an Enrollment's Entry Date falls before the "anniverary". There are two cases because the anniversary may be this year or last year.
      this_year_entered_before_anniversary = start_date.lteq(today).and(e_t[:entry_date].lt(Arel.sql(anniversary_date)))
      last_year_entered_before_anniversary = start_date.gt(today).and(e_t[:entry_date].lt(Arel.sql(last_year_anniversary_date)))
      entered_before_anniversary = this_year_entered_before_anniversary.or(last_year_entered_before_anniversary)

      enrollments_with_annual_due = scope.
        joins(:household).
        # Left outer join with non-WIP Annual Assessments that fall within the relevant Due Period
        joins(
          e_t.
          join(cas_t, Arel::Nodes::OuterJoin).
          on(
            cas_t[:enrollment_id].eq(e_t[:enrollment_id]).
            and(cas_t[:personal_id].eq(e_t[:personal_id])).
            and(cas_t[:data_source_id].eq(e_t[:data_source_id])).
            and(cas_t[:data_collection_stage]).eq(5). # Annual
            and(cas_t[:wip]).eq(false).
            and(cas_t[:DateDeleted]).eq(nil).
            and(annual_in_range),
          ).join_sources,
        ).
        # Earliest entry in household was more than a year ago
        where(hh_t[:earliest_entry].lteq(Date.current - 11.months)).
        # Household is not fully exited
        where(hh_t[:latest_exit].eq(nil)).
        # Client entered household before anniversary date
        where(entered_before_anniversary).
        # Enrollment does not have an Annual Assessment in due period
        where(cas_t[:assessment_date].eq(nil))

      scope.where(id: enrollments_with_annual_due.pluck(:id))
    end
  end

  def with_assigned_staff(scope)
    with_filter(scope, :assigned_staff) do
      sa_t = Hmis::StaffAssignment.arel_table
      scope.joins(household: :staff_assignments).where(sa_t[:user_id].eq(input.assigned_staff))
    end
  end
end
